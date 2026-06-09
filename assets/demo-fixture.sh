#!/usr/bin/env bash
# demo-fixture.sh — builds a small-but-real Go service in $PWD so the demo
# GIFs show ATLAS on believable code (a measurable reduction, a real module
# graph), not a toy that's "smaller than the spine".
#
# Usage (from inside a fresh, empty git repo):  bash demo-fixture.sh
# Used by the vhs tapes in this directory. Self-contained, no network.
set -euo pipefail

mkdir -p cmd/shopd internal/auth internal/cart internal/order internal/catalog \
         internal/payment internal/inventory internal/store internal/httpapi \
         pkg/money config migrations docs

cat > go.mod <<'EOF'
module github.com/acme/shopd

go 1.22

require (
	github.com/jackc/pgx/v5 v5.5.1
	github.com/golang-jwt/jwt/v5 v5.2.0
)
EOF

cat > README.md <<'EOF'
# shopd — a small commerce backend

`shopd` is a JSON/HTTP service for a storefront: a product catalog, a cart,
checkout into orders, payment capture, and session auth. It is deliberately
small and boring — Postgres for state, no message bus, no microservices, no
ORM. The whole thing is one binary in front of one database.

The goal of this codebase is to be *legible*: a new engineer (or agent) should
be able to find where anything lives in under a minute, which is exactly what
the package layout below is for.

## Layout

| Package | Responsibility |
|---|---|
| `cmd/shopd`         | Process entrypoint: config, the pgx pool, graceful shutdown. |
| `internal/auth`     | Login, bcrypt password verification, JWT sessions, the `RequireUser` middleware. |
| `internal/catalog`  | Product listing and lookup (read-mostly). |
| `internal/cart`     | Per-request cart: add/remove line items and compute the total. |
| `internal/order`    | Checkout — turn a cart into a persisted, transactional order. |
| `internal/payment`  | Payment capture against the order total (pluggable provider). |
| `internal/inventory`| Stock levels and the reserve/release flow used at checkout. |
| `internal/store`    | The Postgres layer (pgx). One pool, shared by every package. |
| `internal/httpapi`  | Router + middleware that glue the service packages to HTTP. |
| `pkg/money`         | Integer-cents money type. Never float a currency. |
| `config`            | Env-driven configuration, validated at boot. |

## Architecture

A request enters through `httpapi.Router`, passes the logging and (for
protected routes) the `RequireUser` middleware, and is dispatched to exactly
one service package. Service packages never talk to each other's tables — they
share only `store.DB` and the `money` value type.

    HTTP ──▶ httpapi.Router ──▶ {auth, catalog, cart, order, payment, inventory}
                                          │
                                          ▼
                                     store.DB (pgx pool) ──▶ Postgres

Checkout is the one multi-package flow: `order.Checkout` reserves stock via
`inventory`, writes the order and its lines in a single transaction, then asks
`payment` to capture the total. If capture fails, the transaction rolls back
and the reservation is released.

## HTTP API

| Method & path     | Auth | Description |
|---|---|---|
| `POST /login`     | none | Exchange email + password for a session token. |
| `GET  /products`  | none | List the catalog. |
| `POST /cart`      | user | Add a line item to the caller's cart. |
| `POST /checkout`  | user | Reserve stock, create the order, capture payment. |

All bodies are JSON. Authenticated routes expect `Authorization: Bearer <jwt>`.

## Data model

Five tables: `users`, `products`, `orders`, `order_lines`, and `inventory`.
See `migrations/0001_init.sql` for the canonical schema. Money columns are
always `BIGINT` cents; there are no floating-point currency columns anywhere.

## Configuration

Configuration is read from the environment at startup and validated before the
server binds. Missing required values are a hard boot failure, never a default.

| Variable       | Required | Meaning |
|---|---|---|
| `DATABASE_URL` | yes | pgx connection string. |
| `JWT_SECRET`   | yes | HMAC secret for session tokens. |
| `ADDR`         | no  | Listen address, default `:8080`. |
| `PAYMENT_MODE` | no  | `stub` (default) or `live`. |

## Run

    createdb shopd && psql shopd < migrations/0001_init.sql
    DATABASE_URL=postgres:///shopd JWT_SECRET=dev go run ./cmd/shopd

## Test

    go test ./...

The unit tests are pure (no database): `money`, `cart`, and `auth` round-trips
cover the logic that is easy to get subtly wrong.

## Conventions

- Money is always `money.Cents` (integer). Floating a currency is a bug.
- Every package takes `*store.DB`; nobody opens its own pool.
- Checkout is transactional: order + lines + reservation commit together.
- Auth is stateless: the JWT *is* the session; there is no server-side store.
- `internal/` is private by Go convention — the public surface is HTTP only.
EOF

cat > cmd/shopd/main.go <<'EOF'
// Command shopd is the storefront API server.
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/acme/shopd/config"
	"github.com/acme/shopd/internal/httpapi"
	"github.com/acme/shopd/internal/store"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	db, err := store.Open(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("store: %v", err)
	}
	defer db.Close()

	srv := &http.Server{
		Addr:         cfg.Addr,
		Handler:      httpapi.Router(db, cfg),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	go func() {
		log.Printf("listening on %s", cfg.Addr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("serve: %v", err)
		}
	}()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()
	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdownCtx)
}
EOF

cat > config/config.go <<'EOF'
// Package config loads runtime configuration from the environment.
package config

import (
	"fmt"
	"os"
)

type Config struct {
	Addr        string
	DatabaseURL string
	JWTSecret   []byte
}

func Load() (*Config, error) {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}
	return &Config{Addr: addr, DatabaseURL: url, JWTSecret: []byte(secret)}, nil
}
EOF

cat > pkg/money/money.go <<'EOF'
// Package money is an integer-cents currency type. Never represent money as a
// float — rounding errors compound across a cart.
package money

import "fmt"

type Cents int64

func FromDollars(d float64) Cents { return Cents(d*100 + 0.5) }

func (c Cents) Add(o Cents) Cents { return c + o }
func (c Cents) Mul(n int) Cents   { return c * Cents(n) }

func (c Cents) String() string {
	return fmt.Sprintf("$%d.%02d", c/100, c%100)
}
EOF

cat > internal/store/postgres.go <<'EOF'
// Package store is the Postgres persistence layer. One pool, shared.
package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct{ pool *pgxpool.Pool }

func Open(ctx context.Context, url string) (*DB, error) {
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, err
	}
	return &DB{pool: pool}, nil
}

func (db *DB) Close() { db.pool.Close() }

func (db *DB) Pool() *pgxpool.Pool { return db.pool }
EOF

cat > internal/auth/auth.go <<'EOF'
// Package auth handles login and JWT-backed sessions.
package auth

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/acme/shopd/internal/store"
)

var ErrBadCredentials = errors.New("auth: bad credentials")

type Service struct {
	db     *store.DB
	secret []byte
}

func New(db *store.DB, secret []byte) *Service { return &Service{db: db, secret: secret} }

// Login verifies a user and returns a signed session token.
func (s *Service) Login(ctx context.Context, email, password string) (string, error) {
	id, hash, err := s.lookup(ctx, email)
	if err != nil || !verify(hash, password) {
		return "", ErrBadCredentials
	}
	return s.issue(id)
}

func (s *Service) issue(userID int64) (string, error) {
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": userID,
		"exp": time.Now().Add(24 * time.Hour).Unix(),
	})
	return tok.SignedString(s.secret)
}

func (s *Service) lookup(ctx context.Context, email string) (int64, string, error) {
	var id int64
	var hash string
	err := s.db.Pool().QueryRow(ctx,
		`SELECT id, password_hash FROM users WHERE email = $1`, email).Scan(&id, &hash)
	return id, hash, err
}
EOF

cat > internal/auth/session.go <<'EOF'
package auth

import (
	"golang.org/x/crypto/bcrypt"
)

func verify(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

// Hash is used by the signup path and by test fixtures.
func Hash(password string) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(b), err
}
EOF

cat > internal/auth/auth_test.go <<'EOF'
package auth

import "testing"

func TestVerifyRoundTrip(t *testing.T) {
	hash, err := Hash("hunter2")
	if err != nil {
		t.Fatalf("hash: %v", err)
	}
	if !verify(hash, "hunter2") {
		t.Fatal("correct password rejected")
	}
	if verify(hash, "wrong") {
		t.Fatal("wrong password accepted")
	}
}
EOF

cat > internal/catalog/catalog.go <<'EOF'
// Package catalog lists and looks up products.
package catalog

import (
	"context"

	"github.com/acme/shopd/internal/store"
	"github.com/acme/shopd/pkg/money"
)

type Product struct {
	ID    int64
	Name  string
	Price money.Cents
}

type Service struct{ db *store.DB }

func New(db *store.DB) *Service { return &Service{db: db} }

func (s *Service) List(ctx context.Context) ([]Product, error) {
	rows, err := s.db.Pool().Query(ctx, `SELECT id, name, price_cents FROM products ORDER BY name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Product
	for rows.Next() {
		var p Product
		if err := rows.Scan(&p.ID, &p.Name, &p.Price); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}
EOF

cat > internal/cart/cart.go <<'EOF'
// Package cart holds a per-user collection of line items.
package cart

import "github.com/acme/shopd/pkg/money"

type Line struct {
	ProductID int64
	Unit      money.Cents
	Qty       int
}

type Cart struct{ Lines []Line }

func (c *Cart) Add(productID int64, unit money.Cents, qty int) {
	for i := range c.Lines {
		if c.Lines[i].ProductID == productID {
			c.Lines[i].Qty += qty
			return
		}
	}
	c.Lines = append(c.Lines, Line{ProductID: productID, Unit: unit, Qty: qty})
}

func (c *Cart) Total() money.Cents {
	var t money.Cents
	for _, l := range c.Lines {
		t = t.Add(l.Unit.Mul(l.Qty))
	}
	return t
}
EOF

cat > internal/cart/cart_test.go <<'EOF'
package cart

import (
	"testing"

	"github.com/acme/shopd/pkg/money"
)

func TestCartTotalsAndMerges(t *testing.T) {
	var c Cart
	c.Add(1, money.FromDollars(2.50), 2)
	c.Add(1, money.FromDollars(2.50), 1) // merges into the same line
	c.Add(2, money.FromDollars(10), 1)
	if got := len(c.Lines); got != 2 {
		t.Fatalf("want 2 lines, got %d", got)
	}
	if got := c.Total(); got != money.FromDollars(17.50) {
		t.Fatalf("want $17.50, got %s", got)
	}
}
EOF

cat > internal/order/order.go <<'EOF'
// Package order turns a cart into a persisted, paid order.
package order

import (
	"context"
	"errors"

	"github.com/acme/shopd/internal/cart"
	"github.com/acme/shopd/internal/store"
	"github.com/acme/shopd/pkg/money"
)

var ErrEmptyCart = errors.New("order: cart is empty")

type Order struct {
	ID     int64
	UserID int64
	Total  money.Cents
}

type Service struct{ db *store.DB }

func New(db *store.DB) *Service { return &Service{db: db} }

// Checkout writes the order and its lines in a single transaction.
func (s *Service) Checkout(ctx context.Context, userID int64, c *cart.Cart) (*Order, error) {
	if len(c.Lines) == 0 {
		return nil, ErrEmptyCart
	}
	tx, err := s.db.Pool().Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	o := &Order{UserID: userID, Total: c.Total()}
	if err := tx.QueryRow(ctx,
		`INSERT INTO orders (user_id, total_cents) VALUES ($1,$2) RETURNING id`,
		userID, int64(o.Total)).Scan(&o.ID); err != nil {
		return nil, err
	}
	for _, l := range c.Lines {
		if _, err := tx.Exec(ctx,
			`INSERT INTO order_lines (order_id, product_id, unit_cents, qty) VALUES ($1,$2,$3,$4)`,
			o.ID, l.ProductID, int64(l.Unit), l.Qty); err != nil {
			return nil, err
		}
	}
	return o, tx.Commit(ctx)
}
EOF

cat > internal/httpapi/router.go <<'EOF'
// Package httpapi wires the service packages to HTTP routes.
package httpapi

import (
	"net/http"

	"github.com/acme/shopd/config"
	"github.com/acme/shopd/internal/auth"
	"github.com/acme/shopd/internal/catalog"
	"github.com/acme/shopd/internal/store"
)

func Router(db *store.DB, cfg *config.Config) http.Handler {
	authSvc := auth.New(db, cfg.JWTSecret)
	cat := catalog.New(db)

	mux := http.NewServeMux()
	mux.HandleFunc("POST /login", loginHandler(authSvc))
	mux.HandleFunc("GET /products", listProducts(cat))
	mux.Handle("POST /checkout", RequireUser(cfg.JWTSecret, checkoutHandler(db)))
	return Logging(mux)
}
EOF

cat > internal/httpapi/middleware.go <<'EOF'
package httpapi

import (
	"context"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type ctxKey int

const userKey ctxKey = 0

// RequireUser rejects requests without a valid bearer session token.
func RequireUser(secret []byte, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
		tok, err := jwt.Parse(raw, func(*jwt.Token) (any, error) { return secret, nil })
		if err != nil || !tok.Valid {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		claims := tok.Claims.(jwt.MapClaims)
		ctx := context.WithValue(r.Context(), userKey, int64(claims["sub"].(float64)))
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// Logging records method, path, and latency for every request.
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start))
	})
}
EOF

cat > migrations/0001_init.sql <<'EOF'
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    email         TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);

CREATE TABLE products (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    price_cents BIGINT NOT NULL
);

CREATE TABLE orders (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    total_cents BIGINT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_lines (
    order_id   BIGINT NOT NULL REFERENCES orders(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    unit_cents BIGINT NOT NULL,
    qty        INT NOT NULL
);

CREATE TABLE inventory (
    product_id BIGINT PRIMARY KEY REFERENCES products(id),
    on_hand    INT NOT NULL DEFAULT 0
);
EOF

cat > docs/ARCHITECTURE.md <<'EOF'
# Architecture

shopd is a single binary in front of one Postgres database.

    HTTP ──▶ httpapi.Router
                │
                ├─ auth.Service     (login, RequireUser middleware)
                ├─ catalog.Service  (product reads)
                ├─ cart.Cart        (in-memory, per request)
                └─ order.Service    (checkout, one transaction)
                        │
                        ▼
                   store.DB (pgx pool)

## Rules
- Money is always `money.Cents` (integer). Never float a currency.
- Every package takes `*store.DB`; nobody opens its own pool.
- Checkout is transactional: order + all lines commit together or not at all.
- Auth is stateless: a JWT is the session; there is no server-side store.
EOF

cat > internal/payment/payment.go <<'EOF'
// Package payment captures a charge against an order total. The provider is an
// interface so tests (and the default `stub` mode) need no network.
package payment

import (
	"context"
	"errors"
	"fmt"

	"github.com/acme/shopd/pkg/money"
)

var (
	ErrDeclined = errors.New("payment: declined")
	ErrAmount   = errors.New("payment: amount must be positive")
)

// Provider is the seam between shopd and a real processor (Stripe, Adyen, …).
type Provider interface {
	Capture(ctx context.Context, amount money.Cents, token string) (string, error)
}

// Service captures payments through a Provider.
type Service struct{ p Provider }

func New(p Provider) *Service { return &Service{p: p} }

// Capture validates the amount and delegates to the provider, returning a
// provider-side charge id on success.
func (s *Service) Capture(ctx context.Context, amount money.Cents, token string) (string, error) {
	if amount <= 0 {
		return "", ErrAmount
	}
	if token == "" {
		return "", fmt.Errorf("payment: missing card token")
	}
	id, err := s.p.Capture(ctx, amount, token)
	if err != nil {
		return "", fmt.Errorf("capture %s: %w", amount, err)
	}
	return id, nil
}

// Stub is the default Provider: it approves everything and is used in dev and
// in tests. Swap in a live provider by setting PAYMENT_MODE=live.
type Stub struct{}

func (Stub) Capture(_ context.Context, amount money.Cents, _ string) (string, error) {
	if amount <= 0 {
		return "", ErrAmount
	}
	return fmt.Sprintf("ch_stub_%d", int64(amount)), nil
}
EOF

cat > internal/inventory/inventory.go <<'EOF'
// Package inventory tracks stock levels and the reserve/release flow that
// checkout depends on. Reservations are pessimistic: a row is decremented
// inside the checkout transaction so two carts can't oversell the last unit.
package inventory

import (
	"context"
	"errors"

	"github.com/acme/shopd/internal/store"
)

var ErrOutOfStock = errors.New("inventory: out of stock")

type Service struct{ db *store.DB }

func New(db *store.DB) *Service { return &Service{db: db} }

// Level returns the on-hand quantity for a product.
func (s *Service) Level(ctx context.Context, productID int64) (int, error) {
	var n int
	err := s.db.Pool().QueryRow(ctx,
		`SELECT on_hand FROM inventory WHERE product_id = $1`, productID).Scan(&n)
	return n, err
}

// Reserve decrements stock for a product or fails if there isn't enough. It is
// safe to call inside an open transaction (and checkout always does).
func (s *Service) Reserve(ctx context.Context, productID int64, qty int) error {
	tag, err := s.db.Pool().Exec(ctx,
		`UPDATE inventory SET on_hand = on_hand - $2
		   WHERE product_id = $1 AND on_hand >= $2`, productID, qty)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrOutOfStock
	}
	return nil
}

// Release returns reserved stock after a failed checkout.
func (s *Service) Release(ctx context.Context, productID int64, qty int) error {
	_, err := s.db.Pool().Exec(ctx,
		`UPDATE inventory SET on_hand = on_hand + $2 WHERE product_id = $1`,
		productID, qty)
	return err
}
EOF

git add -A >/dev/null 2>&1 || true
