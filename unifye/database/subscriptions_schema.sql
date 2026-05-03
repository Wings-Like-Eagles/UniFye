-- ===========================================================================
-- UniFye Subscription System — PostgreSQL Schema
-- Version: 1.0 | Date: 2026-04-15
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- ENUM: subscription_tier
-- Represents the 4 plan tiers available in UniFye
-- ---------------------------------------------------------------------------
CREATE TYPE subscription_tier AS ENUM (
    'free',
    'plus',
    'community_pro',
    'campus_enterprise'
);

-- ---------------------------------------------------------------------------
-- ENUM: subscription_status
-- Mirrors Stripe subscription lifecycle statuses
-- ---------------------------------------------------------------------------
CREATE TYPE subscription_status AS ENUM (
    'active',
    'trialing',
    'past_due',
    'canceled',
    'unpaid',
    'paused'
);

-- ---------------------------------------------------------------------------
-- ENUM: analytics_access_level
-- Controls the depth of analytics features unlocked per plan
-- ---------------------------------------------------------------------------
CREATE TYPE analytics_access_level AS ENUM (
    'none',
    'basic',
    'advanced'
);

-- ===========================================================================
-- TABLE: subscription_plans
-- Master reference table for all available subscription plan definitions.
-- Seeded at deployment time; rarely mutated at runtime.
-- ===========================================================================
CREATE TABLE subscription_plans (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier                        subscription_tier       NOT NULL UNIQUE,
    display_name                VARCHAR(100)            NOT NULL,
    description                 TEXT,
    badge_label                 VARCHAR(50),            -- e.g. "Most Popular", "Best Value"
    badge_colour_hex            VARCHAR(7),             -- e.g. "#FF4B6E"
    monthly_price_zar           NUMERIC(10, 2)          NOT NULL DEFAULT 0.00,
    annual_price_zar            NUMERIC(10, 2),         -- NULL means no annual option
    stripe_product_id           VARCHAR(255),           -- e.g. "prod_plus_unifye"
    stripe_monthly_price_id     VARCHAR(255),           -- e.g. "price_plus_monthly_zar"
    stripe_annual_price_id      VARCHAR(255),           -- e.g. "price_plus_annual_zar"
    is_active                   BOOLEAN                 NOT NULL DEFAULT TRUE,
    sort_order                  INT                     NOT NULL DEFAULT 0,
    created_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- COMMENT: subscription_plans
-- ---------------------------------------------------------------------------
COMMENT ON TABLE subscription_plans IS
    'Master list of UniFye subscription tiers. Seeded on deploy.';
COMMENT ON COLUMN subscription_plans.stripe_product_id IS
    'Matches the Stripe Product ID in the UniFye Stripe account.';
COMMENT ON COLUMN subscription_plans.annual_price_zar IS
    'NULL if no annual billing option exists for this tier.';

-- ===========================================================================
-- TABLE: plan_feature_permissions
-- Stores the concrete permission values for each subscription plan.
-- The C# permission resolver reads from this table at runtime.
-- -1 on numeric fields = unlimited
-- ===========================================================================
CREATE TABLE plan_feature_permissions (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id                     UUID                    NOT NULL REFERENCES subscription_plans(id) ON DELETE CASCADE,
    tier                        subscription_tier       NOT NULL UNIQUE,

    -- Swipe & Match
    daily_swipe_limit           INT                     NOT NULL DEFAULT 10,
    max_active_matches          INT                     NOT NULL DEFAULT 3,
    can_see_who_liked_me        BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Messaging
    can_send_media              BOOLEAN                 NOT NULL DEFAULT FALSE,
    can_send_voice_notes        BOOLEAN                 NOT NULL DEFAULT FALSE,
    has_read_receipts           BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Profile
    weekly_profile_boost_count  INT                     NOT NULL DEFAULT 0,
    has_verified_organiser_badge BOOLEAN                NOT NULL DEFAULT FALSE,

    -- Communities
    max_joined_communities      INT                     NOT NULL DEFAULT 1,
    can_create_community        BOOLEAN                 NOT NULL DEFAULT FALSE,
    max_owned_communities       INT                     NOT NULL DEFAULT 0,
    community_member_cap        INT                     NOT NULL DEFAULT 0,

    -- Events
    can_create_events           BOOLEAN                 NOT NULL DEFAULT FALSE,
    monthly_event_limit         INT                     NOT NULL DEFAULT 0,
    event_attendee_cap          INT,                    -- NULL = no cap enforced at plan level
    can_generate_qr_checkin     BOOLEAN                 NOT NULL DEFAULT FALSE,
    can_export_attendees        BOOLEAN                 NOT NULL DEFAULT FALSE,
    can_pin_announcements       BOOLEAN                 NOT NULL DEFAULT FALSE,
    events_priority_listing     BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Analytics
    analytics_access            analytics_access_level  NOT NULL DEFAULT 'none',
    can_export_analytics_pdf    BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Admin & Enterprise
    max_account_admins          INT                     NOT NULL DEFAULT 1,
    can_broadcast_messages      BOOLEAN                 NOT NULL DEFAULT FALSE,
    has_webhook_access          BOOLEAN                 NOT NULL DEFAULT FALSE,
    has_white_label             BOOLEAN                 NOT NULL DEFAULT FALSE,
    has_sla_support             BOOLEAN                 NOT NULL DEFAULT FALSE,
    has_dedicated_manager       BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Leaderboard
    leaderboard_visibility_cap  INT                     NOT NULL DEFAULT 10,

    created_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE plan_feature_permissions IS
    'Concrete permission values per subscription tier. -1 on INT fields = unlimited.';
COMMENT ON COLUMN plan_feature_permissions.daily_swipe_limit IS
    '-1 = unlimited swipes per day.';
COMMENT ON COLUMN plan_feature_permissions.max_active_matches IS
    '-1 = unlimited concurrent matches.';
COMMENT ON COLUMN plan_feature_permissions.monthly_event_limit IS
    '-1 = unlimited event creation per month.';

-- ===========================================================================
-- TABLE: user_subscriptions
-- The live subscription record per user. One row = one active subscription.
-- Historical records are preserved for audit via status transitions.
-- ===========================================================================
CREATE TABLE user_subscriptions (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID                    NOT NULL,
    plan_id                     UUID                    NOT NULL REFERENCES subscription_plans(id),
    tier                        subscription_tier       NOT NULL DEFAULT 'free',
    status                      subscription_status     NOT NULL DEFAULT 'active',

    -- Stripe Integration
    stripe_customer_id          VARCHAR(255),           -- e.g. "cus_XXXXX"
    stripe_subscription_id      VARCHAR(255),           -- e.g. "sub_XXXXX"
    stripe_price_id             VARCHAR(255),           -- Active price ID
    is_annual_billing           BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Period Tracking
    current_period_start        TIMESTAMPTZ,
    current_period_end          TIMESTAMPTZ,
    trial_start                 TIMESTAMPTZ,
    trial_end                   TIMESTAMPTZ,
    canceled_at                 TIMESTAMPTZ,
    cancel_at_period_end        BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- Grace period for failed payments
    grace_period_end            TIMESTAMPTZ,

    -- Metadata
    created_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    -- One active subscription row per user (enforced via partial unique index below)
    CONSTRAINT uq_user_active_subscription UNIQUE (user_id)
);

COMMENT ON TABLE user_subscriptions IS
    'Current subscription record per user. Mirrors Stripe subscription state.';
COMMENT ON COLUMN user_subscriptions.stripe_customer_id IS
    'Stripe Customer ID — used to manage billing portal access.';
COMMENT ON COLUMN user_subscriptions.grace_period_end IS
    'If payment fails, user retains access until this timestamp before being downgraded.';

-- Index: fast lookup by Stripe IDs for webhook processing
CREATE INDEX idx_user_subscriptions_stripe_sub_id
    ON user_subscriptions (stripe_subscription_id);

CREATE INDEX idx_user_subscriptions_stripe_customer_id
    ON user_subscriptions (stripe_customer_id);

CREATE INDEX idx_user_subscriptions_user_id
    ON user_subscriptions (user_id);

CREATE INDEX idx_user_subscriptions_tier
    ON user_subscriptions (tier);

-- ===========================================================================
-- TABLE: subscription_history
-- Immutable audit log of every subscription state change.
-- Never deleted — used for billing disputes, analytics, and churn tracking.
-- ===========================================================================
CREATE TABLE subscription_history (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID                    NOT NULL,
    subscription_id             UUID                    NOT NULL REFERENCES user_subscriptions(id),
    previous_tier               subscription_tier,
    new_tier                    subscription_tier       NOT NULL,
    previous_status             subscription_status,
    new_status                  subscription_status     NOT NULL,
    change_reason               VARCHAR(255),           -- e.g. "stripe_webhook", "admin_override", "trial_ended"
    stripe_event_id             VARCHAR(255),           -- Idempotency key from Stripe webhook
    metadata                    JSONB,                  -- Any extra Stripe event data
    changed_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE subscription_history IS
    'Append-only audit trail for all subscription tier and status changes.';
COMMENT ON COLUMN subscription_history.stripe_event_id IS
    'Stripe event ID for idempotent webhook processing. Prevents double-processing.';

CREATE INDEX idx_sub_history_user_id ON subscription_history (user_id);
CREATE INDEX idx_sub_history_stripe_event_id ON subscription_history (stripe_event_id);

-- ===========================================================================
-- TABLE: campus_enterprise_accounts
-- Extended profile for Campus/Enterprise plan holders.
-- Supports multi-admin, institutional metadata, and custom configs.
-- ===========================================================================
CREATE TABLE campus_enterprise_accounts (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id             UUID                    NOT NULL REFERENCES user_subscriptions(id),
    institution_name            VARCHAR(255)            NOT NULL,
    institution_type            VARCHAR(100),           -- e.g. "University", "SRC", "Student Society"
    campus_badge_label          VARCHAR(100),           -- e.g. "UCT SRC Official"
    custom_slug                 VARCHAR(100) UNIQUE,    -- e.g. "uct-src" → unifye.co.za/e/uct-src
    contact_email               VARCHAR(255),
    purchase_order_number       VARCHAR(100),
    billing_contact_name        VARCHAR(255),
    admin_user_ids              UUID[],                 -- Array of admin user UUIDs (max 10)
    webhook_url                 TEXT,
    webhook_secret              VARCHAR(255),
    is_white_label_enabled      BOOLEAN                 NOT NULL DEFAULT FALSE,
    notes                       TEXT,                   -- Internal account manager notes
    created_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE campus_enterprise_accounts IS
    'Extended metadata for Campus/Enterprise plan accounts. One per qualifying subscription.';

-- ===========================================================================
-- TABLE: profile_boosts
-- Tracks weekly profile boost usage and scheduling per user.
-- ===========================================================================
CREATE TABLE profile_boosts (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID                    NOT NULL,
    week_start                  DATE                    NOT NULL,
    boosts_used                 INT                     NOT NULL DEFAULT 0,
    last_boosted_at             TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_user_boost_week UNIQUE (user_id, week_start)
);

COMMENT ON TABLE profile_boosts IS
    'Tracks weekly profile boost consumption per user against plan allowance.';

-- ===========================================================================
-- SEED DATA: subscription_plans
-- Base plan data — run after schema migration
-- ===========================================================================
INSERT INTO subscription_plans
    (tier, display_name, description, badge_label, badge_colour_hex,
     monthly_price_zar, annual_price_zar,
     stripe_product_id, stripe_monthly_price_id, stripe_annual_price_id,
     sort_order)
VALUES
    ('free',
     'Free',
     'Get started with UniFye. Meet new people on campus at no cost.',
     NULL, NULL,
     0.00, NULL,
     NULL, NULL, NULL,
     1),

    ('plus',
     'Plus',
     'Unlimited swipes, see who liked you, and send media. The full social experience.',
     'Most Popular', '#FF4B6E',
     49.00, 470.00,
     'prod_plus_unifye', 'price_plus_monthly_zar', 'price_plus_annual_zar',
     2),

    ('community_pro',
     'Community Pro',
     'Create events, manage communities, and track attendance with analytics.',
     'Best Value', '#FF8C00',
     149.00, 1341.00,
     'prod_community_pro_unifye', 'price_pro_monthly_zar', 'price_pro_annual_zar',
     3),

    ('campus_enterprise',
     'Campus / Enterprise',
     'Institutional-grade tools for SRCs, universities, and large student organisations.',
     'Institutional', '#4A90D9',
     999.00, NULL,
     'prod_campus_enterprise_unifye', 'price_campus_monthly_zar', NULL,
     4);

-- ===========================================================================
-- SEED DATA: plan_feature_permissions
-- Insert after subscription_plans seed
-- ===========================================================================
INSERT INTO plan_feature_permissions
    (plan_id, tier,
     daily_swipe_limit, max_active_matches, can_see_who_liked_me,
     can_send_media, can_send_voice_notes, has_read_receipts,
     weekly_profile_boost_count, has_verified_organiser_badge,
     max_joined_communities, can_create_community, max_owned_communities, community_member_cap,
     can_create_events, monthly_event_limit, event_attendee_cap,
     can_generate_qr_checkin, can_export_attendees, can_pin_announcements, events_priority_listing,
     analytics_access, can_export_analytics_pdf,
     max_account_admins, can_broadcast_messages, has_webhook_access,
     has_white_label, has_sla_support, has_dedicated_manager,
     leaderboard_visibility_cap)
VALUES
    -- FREE
    ((SELECT id FROM subscription_plans WHERE tier = 'free'), 'free',
     10, 3, FALSE,
     FALSE, FALSE, FALSE,
     0, FALSE,
     1, FALSE, 0, 0,
     FALSE, 0, NULL,
     FALSE, FALSE, FALSE, FALSE,
     'none', FALSE,
     1, FALSE, FALSE, FALSE, FALSE, FALSE,
     10),

    -- PLUS
    ((SELECT id FROM subscription_plans WHERE tier = 'plus'), 'plus',
     -1, -1, TRUE,
     TRUE, TRUE, TRUE,
     1, FALSE,
     5, FALSE, 0, 0,
     FALSE, 0, NULL,
     FALSE, FALSE, FALSE, FALSE,
     'none', FALSE,
     1, FALSE, FALSE, FALSE, FALSE, FALSE,
     100),

    -- COMMUNITY PRO
    ((SELECT id FROM subscription_plans WHERE tier = 'community_pro'), 'community_pro',
     -1, -1, TRUE,
     TRUE, TRUE, TRUE,
     3, TRUE,
     10, TRUE, 1, 200,
     TRUE, 3, NULL,
     TRUE, TRUE, TRUE, TRUE,
     'basic', FALSE,
     1, FALSE, FALSE, FALSE, FALSE, FALSE,
     -1),

    -- CAMPUS / ENTERPRISE
    ((SELECT id FROM subscription_plans WHERE tier = 'campus_enterprise'), 'campus_enterprise',
     -1, -1, TRUE,
     TRUE, TRUE, TRUE,
     -1, TRUE,
     -1, TRUE, -1, -1,
     TRUE, -1, NULL,
     TRUE, TRUE, TRUE, TRUE,
     'advanced', TRUE,
     10, TRUE, TRUE, TRUE, TRUE, TRUE,
     -1);

-- ===========================================================================
-- HELPER FUNCTION: get_user_permissions(user_id UUID)
-- Returns the resolved permissions for a given user based on their active
-- subscription plan. Used by C# to avoid multiple queries.
-- ===========================================================================
CREATE OR REPLACE FUNCTION get_user_permissions(p_user_id UUID)
RETURNS TABLE (
    tier                        subscription_tier,
    status                      subscription_status,
    daily_swipe_limit           INT,
    max_active_matches          INT,
    can_see_who_liked_me        BOOLEAN,
    can_send_media              BOOLEAN,
    can_create_events           BOOLEAN,
    monthly_event_limit         INT,
    analytics_access            analytics_access_level,
    max_joined_communities      INT,
    can_create_community        BOOLEAN,
    weekly_profile_boost_count  INT,
    leaderboard_visibility_cap  INT
)
LANGUAGE sql STABLE
AS $$
    SELECT
        us.tier,
        us.status,
        pfp.daily_swipe_limit,
        pfp.max_active_matches,
        pfp.can_see_who_liked_me,
        pfp.can_send_media,
        pfp.can_create_events,
        pfp.monthly_event_limit,
        pfp.analytics_access,
        pfp.max_joined_communities,
        pfp.can_create_community,
        pfp.weekly_profile_boost_count,
        pfp.leaderboard_visibility_cap
    FROM user_subscriptions us
    JOIN plan_feature_permissions pfp ON pfp.tier = us.tier
    WHERE us.user_id = p_user_id
    LIMIT 1;
$$;

COMMENT ON FUNCTION get_user_permissions IS
    'Resolves the merged subscription permissions for a given user. Used by the C# PermissionService.';

-- ===========================================================================
-- TRIGGER: auto-update updated_at on row changes
-- ===========================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_subscription_plans_updated_at
    BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_plan_permissions_updated_at
    BEFORE UPDATE ON plan_feature_permissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_user_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_campus_accounts_updated_at
    BEFORE UPDATE ON campus_enterprise_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_profile_boosts_updated_at
    BEFORE UPDATE ON profile_boosts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
