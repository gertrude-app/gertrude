import FluentSQL
import Foundation

struct AddBillingIdentities: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    // remove stripe id from complimentary users (just liv)
    try await sql.execute("""
      UPDATE parent.subscriptions
      SET stripe_id = NULL, updated_at = NOW()
      WHERE billing_status IS NULL
        AND tier::TEXT = 'full'
        AND stripe_id IS NOT NULL;
    """)

    try await sql.execute("""
      CREATE TABLE parent.billing_identities (
        id UUID PRIMARY KEY,
        parent_id UUID NOT NULL UNIQUE
          REFERENCES parent.parents(id) ON DELETE CASCADE,
        stripe_customer_id TEXT,
        full_trial_started_at TIMESTAMP WITH TIME ZONE,
        last_stripe_subscription_id TEXT,
        last_paid_tier TEXT
          CHECK (last_paid_tier IS NULL OR last_paid_tier IN ('light', 'full')),
        trial_email_lifecycle TEXT NOT NULL DEFAULT 'none'
          CHECK (trial_email_lifecycle IN
            ('none', 'ending_soon_sent', 'expired_sent', 'final_sent')),
        is_complimentary BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
      );
    """)

    try await sql.execute("""
      INSERT INTO parent.billing_identities (
        id,
        parent_id,
        stripe_customer_id,
        full_trial_started_at,
        last_stripe_subscription_id,
        last_paid_tier,
        trial_email_lifecycle,
        is_complimentary
      )
      SELECT
        gen_random_uuid(),
        parent_id,
        NULL,
        trial_started_at,
        stripe_id,
        CASE WHEN stripe_id IS NOT NULL THEN tier::TEXT ELSE NULL END,
        CASE billing_status::TEXT
          WHEN 'trialExpiringSoon' THEN 'ending_soon_sent'
          WHEN 'trialExpired'      THEN 'expired_sent'
          WHEN 'unpaid'            THEN
            CASE WHEN trial_started_at IS NOT NULL
                 THEN 'final_sent'
                 ELSE 'none'
            END
          ELSE 'none'
        END,
        (billing_status IS NULL AND tier::TEXT = 'full')
      FROM parent.subscriptions
      ON CONFLICT (parent_id) DO NOTHING;
    """)

    try await sql.execute("""
      UPDATE parent.billing_identities AS bi
      SET stripe_customer_id = m.cus_id
      FROM (VALUES
        -- {{ generated VALUES — paste before merge }}
        ('sub_1O6tDhGKRdhETuKAqn0yi8ax', 'cus_Ouifc0mbzhEY6K'),
        ('sub_1O7NXTGKRdhETuKAtNG1wLT9', 'cus_OvDzevRpPM95CL'),
        ('sub_1Ob2jpGKRdhETuKA55QW0NGS', 'cus_PPsU5SvW4OeJcy'),
        ('sub_1OcdECGKRdhETuKAgdDnGH5n', 'cus_PRWGlFHgd8kwPb'),
        ('sub_1Ow3WJGKRdhETuKA1dG0IVD4', 'cus_PlahNNehyIUqh7'),
        ('sub_1P5ObLGKRdhETuKAogRbjgUw', 'cus_PvF5nIfe9P4VhH'),
        ('sub_1PRzpIGKRdhETuKATmrelxiX', 'cus_QIb1KiawMiSddZ'),
        ('sub_1PXif6GKRdhETuKAmFNQfl9M', 'cus_QOVgNUmKEUxD8E'),
        ('sub_1PcXkJGKRdhETuKAxxdmxjV8', 'cus_QTUjsylPZAhtZN'),
        ('sub_1PdYUvGKRdhETuKA0bsl289q', 'cus_QUXaT2yhki83b8'),
        ('sub_1PiPo5GKRdhETuKAOrKeLzgr', 'cus_QZYvKMgC6Vpqu8'),
        ('sub_1PkBnSGKRdhETuKAssyv0fUD', 'cus_QbOaSa8ncUvJMS'),
        ('sub_1PsBYHGKRdhETuKACKpp94i4', 'cus_QjesDWmuOGkXyY'),
        ('sub_1PtEyBGKRdhETuKA1tnXocrh', 'cus_QkkTN6VsKEyrAU'),
        ('sub_1PybvSGKRdhETuKAqOnFAnt9', 'cus_QqIWAFwMR6yMka'),
        ('sub_1Q95AzGKRdhETuKA5qNSS0Fv', 'cus_R17PBvclqpeejv'),
        ('sub_1QCiSQGKRdhETuKASkj0iJoi', 'cus_R4sClhaVUpV0Uw'),
        ('sub_1QHoPsGKRdhETuKAJOPxeYyh', 'cus_RA8hXuWy6C4yCY'),
        ('sub_1QKqIVGKRdhETuKA3TzUOoqM', 'cus_RDGqMJxR6kSBGG'),
        ('sub_1QLECKGKRdhETuKAeNyB4bHy', 'cus_RDfX1IIjvAjC83'),
        ('sub_1QLtGGGKRdhETuKApIGpBeGw', 'cus_RELy9B0omaeAkM'),
        ('sub_1QNcosGKRdhETuKAac9MExSN', 'cus_RG97EasNjU8TNs'),
        ('sub_1QTb9jGKRdhETuKATPYw6AbT', 'cus_RMJnLTVTF2ZQDq'),
        ('sub_1QTqZTGKRdhETuKATFf6PnDG', 'cus_RMZid75nUfDOD7'),
        ('sub_1QU7diGKRdhETuKAXXe0St5H', 'cus_RMrMMLh216b0gj'),
        ('sub_1QUACeGKRdhETuKAqmG7Dmr4', 'cus_RMu0ke1DE7QJXo'),
        ('sub_1QXgoIGKRdhETuKA51bvsrBL', 'cus_RQXuFV0gKjySIn'),
        ('sub_1QcAs5GKRdhETuKAYj7ZMKvo', 'cus_RVBEsBQDQppjyp'),
        ('sub_1QigtnGKRdhETuKAXQUR7bTY', 'cus_RbujHc8Zq8o6aV'),
        ('sub_1QpxXdGKRdhETuKAZYBMzIfG', 'cus_RjQOqUKMVg7ZHB'),
        ('sub_1Qr9FMGKRdhETuKARghtOBJR', 'cus_RkeY6HIP9k81Qk'),
        ('sub_1Qs79pGKRdhETuKAmx1RzDcs', 'cus_RleSUV3pr5gwHD'),
        ('sub_1QsB4wGKRdhETuKAbBbjHzvo', 'cus_RliVqpMulMux55'),
        ('sub_1QtczxGKRdhETuKACdQ0cfQI', 'cus_RnDQcUHq2kw6v0'),
        ('sub_1QzjRlGKRdhETuKAeZ4JBUBM', 'cus_RtWUe8LwVfPXou'),
        ('sub_1R0tTLGKRdhETuKAYO0zMmE6', 'cus_RuivrhRCYZW8g6'),
        ('sub_1R11AZGKRdhETuKAQMTMJkqe', 'cus_RuqsBgciTTTErK'),
        ('sub_1R1U5XGKRdhETuKA6d9dziyZ', 'cus_RvKlU0SQC0ritY'),
        ('sub_1R2bjbGKRdhETuKAjUTNSeoq', 'cus_RwUjnG0PKwZF8n'),
        ('sub_1R59y8GKRdhETuKAIcXs58Fc', 'cus_Rz8EsjriTkxjjr'),
        ('sub_1R5SYPGKRdhETuKAqefFTBzv', 'cus_RzRRAVX6KCYmmk'),
        ('sub_1R5Xf5GKRdhETuKAxUD1NcV0', 'cus_RzWi2lEjHvMIfr'),
        ('sub_1R6LXvGKRdhETuKAb0bUU56P', 'cus_S0MGbYWxAguLYj'),
        ('sub_1R6eVwGKRdhETuKAHOryLSO4', 'cus_S0frH1U1hixrn7'),
        ('sub_1R6jsuGKRdhETuKAzcFvMMyT', 'cus_S0lPZem7EdEZyv'),
        ('sub_1R6z2YGKRdhETuKAnSWcwonP', 'cus_S114AI4xNaoFPw'),
        ('sub_1RB1byGKRdhETuKA7ruDi16L', 'cus_S5BzWv7Pj25mzR'),
        ('sub_1RCIcEGKRdhETuKANwF0Ex0u', 'cus_S6Vdrt6MlDPUEA'),
        ('sub_1RDnngGKRdhETuKAU5pZveZR', 'cus_S83vJDAQOqX1kk'),
        ('sub_1RG0oYGKRdhETuKA5COfI6Pp', 'cus_SALV3oQTh7M83D'),
        ('sub_1RGnPTGKRdhETuKAeTXDKmGS', 'cus_SB9iXyyCpUxZIe'),
        ('sub_1RGoJ5GKRdhETuKAY19PLY2U', 'cus_SBAeelnuovfmz4'),
        ('sub_1RLTE9GKRdhETuKA7g7ZBWK7', 'cus_SFzCXCG6C6smCu'),
        ('sub_1RO3LoGKRdhETuKAW5FSqwVM', 'cus_SIefa5l5JGzHVK'),
        ('sub_1ROmQQGKRdhETuKAHcWTIcQY', 'cus_SJPEREmXQsaaM8'),
        ('sub_1RRjRdGKRdhETuKASS6Yk9dy', 'cus_SMSMtb05SaF8AC'),
        ('sub_1RTB0yGKRdhETuKA1cuxnlwc', 'cus_SNwuFZe5Gzzf1M'),
        ('sub_1RVunWGKRdhETuKAnUIpuS6v', 'cus_SQmMztMIKJTK9U'),
        ('sub_1RXvwQGKRdhETuKAeNqxhIaW', 'cus_SSrfhFq4QtwdaG'),
        ('sub_1RctwtGKRdhETuKAjEqM0k9l', 'cus_SXzwUuhTfSA7cT'),
        ('sub_1Rfcy6GKRdhETuKAPXvOrdGk', 'cus_SaobatrGVUGApr'),
        ('sub_1RlA4tGKRdhETuKA9WhOKYM8', 'cus_SgX97mO1Sfk7zn'),
        ('sub_1RlBPZGKRdhETuKAMuOrnC2V', 'cus_SgYWVEXRveDCfG'),
        ('sub_1Rn2HQGKRdhETuKATmp4AgMu', 'cus_SiTDwCzVLy70Um'),
        ('sub_1Rr3tzGKRdhETuKAKvgmwKyD', 'cus_SmdADuQRHe9yCL'),
        ('sub_1Ry67WGKRdhETuKAauP9Vov7', 'cus_SttvBSGbElD3NN'),
        ('sub_1S1FVQGKRdhETuKAIoRc0M5U', 'cus_Sx9pIzv9lDqMEg'),
        ('sub_1S1M0IGKRdhETuKACqUVtWNa', 'cus_SxGXc7wo2YZhlg'),
        ('sub_1S3SueGKRdhETuKAgI3pA0yG', 'cus_SzRoIbmNDvfxJP'),
        ('sub_1S3z8rGKRdhETuKArQame6IV', 'cus_Szz7iMpPzSpuuM'),
        ('sub_1S5shWGKRdhETuKAg2qbfMGP', 'cus_T1wahwYDXSNXGy'),
        ('sub_1S8gVXGKRdhETuKAIjpbrf1S', 'cus_T4qBYEtdgNxia4'),
        ('sub_1S9zsrGKRdhETuKAEaRphp9Z', 'cus_T6CH6Kszccm64q'),
        ('sub_1SBL34GKRdhETuKA2wDq5j6P', 'cus_T7aDBIiGAW23vF'),
        ('sub_1SC8viGKRdhETuKAhb4ydTmH', 'cus_T8PlcfmAxbgrBW'),
        ('sub_1SHOOrGKRdhETuKAKfqveCEm', 'cus_TDq54pGzdAgCqf'),
        ('sub_1SHpfKGKRdhETuKACFLMFDCO', 'cus_TEIFI5CQ55M6ML'),
        ('sub_1SJ4TNGKRdhETuKASCBQLNfV', 'cus_TFZcXsTgw6pWLD'),
        ('sub_1SL1DVGKRdhETuKA6clbQamj', 'cus_THaOACKw8xmoxp'),
        ('sub_1SOTMQGKRdhETuKAHZE8AcJa', 'cus_TL9fdveR0qx5A9'),
        ('sub_1SSLKPGKRdhETuKAUuLTKRec', 'cus_TP9dNHGG2Xn8IY'),
        ('sub_1SZIFbGKRdhETuKAtPhmtzmn', 'cus_TWKvqkKF6KHsdY'),
        ('sub_1SZLzdGKRdhETuKAWUkxQ0jn', 'cus_TWOnSXFIgFTt63'),
        ('sub_1SdvKpGKRdhETuKAOG1Xejsi', 'cus_Tb7Z0fRHmU7ADW'),
        ('sub_1SdxUPGKRdhETuKAQwLgc4x4', 'cus_Tb9oQS0ZWn7Sru'),
        ('sub_1SeH8lGKRdhETuKAxgFTl2PO', 'cus_TbU6EWGdLXDcgL'),
        ('sub_1SgtyQGKRdhETuKA32nlpHRo', 'cus_TeCNaGcZmlUYBI'),
        ('sub_1SjPjOGKRdhETuKAR6ll4aly', 'cus_TgnKG712AmwlRG'),
        ('sub_1SlGDdGKRdhETuKA5WjIRwZW', 'cus_TihcypqGteDzpH'),
        ('sub_1SpJFXGKRdhETuKANSz3CUjr', 'cus_Tmt1C8RuxhGIE4'),
        ('sub_1Srj4tGKRdhETuKAUrafRzYX', 'cus_TpNqDwqhIdTYdN'),
        ('sub_1SswsoGKRdhETuKANWGDkyJs', 'cus_TqeBgFyBGF3UNI'),
        ('sub_1StxlbGKRdhETuKAnfEyF1Mc', 'cus_Trh947OHcJtJXB'),
        ('sub_1SxD7OGKRdhETuKAUx9AeJMN', 'cus_Tv3DVjpdk7n0sD'),
        ('sub_1SxaT6GKRdhETuKAFa5NGwg0', 'cus_TvRLRjCgkGiJ85'),
        ('sub_1T1DmlGKRdhETuKADaFp98cV', 'cus_TzCBKcg6sZLzan'),
        ('sub_1T1Z0nGKRdhETuKADjroLhVG', 'cus_TzY7mC4CB6sKIz'),
        ('sub_1T20TmGKRdhETuKA4Bdq6R08', 'cus_U00ULRwVkZJk3l'),
        ('sub_1T20YDGKRdhETuKAcZHzyvcK', 'cus_U00ZHnHm8yZ5wh'),
        ('sub_1T2BVpGKRdhETuKAnKhY9voA', 'cus_U0BtORApeR4c7R'),
        ('sub_1T2lkyGKRdhETuKA7ei8VJ6A', 'cus_U0nLY43CmTW6jr'),
        ('sub_1T30OrGKRdhETuKAbit4OVVP', 'cus_U12TE0lis86RlN'),
        ('sub_1T3a3vGKRdhETuKAMuxOCPlo', 'cus_U1dKOVRjLvMpJf'),
        ('sub_1T43B4GKRdhETuKA2R818yBE', 'cus_U27PzqBbP4C5Sk'),
        ('sub_1T4DLWGKRdhETuKAdFtxUab5', 'cus_U2HvZrmXFvoyq1'),
        ('sub_1T4PU8GKRdhETuKA7ys4mvgs', 'cus_U2UTfa70jKm58C'),
        ('sub_1T4uV4GKRdhETuKAOj7AwTdx', 'cus_U30Wa1CyX6wzR7'),
        ('sub_1T5cWJGKRdhETuKAuou2MBIv', 'cus_U3k0cPhJjpCP8y'),
        ('sub_1T60v9GKRdhETuKACFJOBc2u', 'cus_U49DHDFH948cp3'),
        ('sub_1T6LHdGKRdhETuKAXhoVPkcy', 'cus_U4UGWylkwdqHUm'),
        ('sub_1T6Np0GKRdhETuKA4SvhuSvR', 'cus_U4WsbVcdm7Pmf1'),
        ('sub_1T6e8HGKRdhETuKARpaV01Vd', 'cus_U4njEskzcMQLiA'),
        ('sub_1T6fs8GKRdhETuKAO42myBDC', 'cus_U4pXYkeba2Acgz'),
        ('sub_1T7CMiGKRdhETuKAcBEosTDn', 'cus_U5N60WUbkVK1qN'),
        ('sub_1T7YjoGKRdhETuKAFFSyzAWg', 'cus_U5kEugpyB4uyPs'),
        ('sub_1TA8cKGKRdhETuKATcQNOK7W', 'cus_U8PR9E8yOJYYSW'),
        ('sub_1TBRNCGKRdhETuKAeBmprtMP', 'cus_U9ksCOaSstDPnE'),
        ('sub_1TDHv4GKRdhETuKAzkrzCnqz', 'cus_UBfFB40uiFGWcj'),
        ('sub_1TEeoUGKRdhETuKAm4OAfFg8', 'cus_UD4y6cqOcx6AoY'),
        ('sub_1TFEXPGKRdhETuKAjF2tRwka', 'cus_UDftGV5puDLZIF'),
        ('sub_1TFQkAGKRdhETuKAiA9WkFiD', 'cus_UDsV0287aFy532'),
        ('sub_1TFgz3GKRdhETuKAxNk2sI4J', 'cus_UE9H2ntVkvQhOE'),
        ('sub_1TGPTJGKRdhETuKASsJ8i3oY', 'cus_UEtFTXbyTbrnw2'),
        ('sub_1TGYMuGKRdhETuKAFVrgqo7j', 'cus_UF2RepTLUhpMQL'),
        ('sub_1TH8YxGKRdhETuKALYM8fTQD', 'cus_UFdq3JNphPsfyL'),
        ('sub_1THRUVGKRdhETuKAZ4bUCbmG', 'cus_UFxPyxUJLV6yCu'),
        ('sub_1TIei4GKRdhETuKAXQwxmQY7', 'cus_UHD8MPgjlbqmEx'),
        ('sub_1TJ2ERGKRdhETuKAOFpORP6J', 'cus_UHbRqb97ELzrP8'),
        ('sub_1TJDMwGKRdhETuKAHIhubhY9', 'cus_UHmwjbRAfmZHWq'),
        ('sub_1TJeFTGKRdhETuKAI6g6SepJ', 'cus_UIEiHid1IaNVSn'),
        ('sub_1TJlTVGKRdhETuKAY8TZfjV4', 'cus_UIMBSKymE8UXW4'),
        ('sub_1TJv2KGKRdhETuKApp6qMku8', 'cus_UIW4ZHcn2wszGG'),
        ('sub_1TKe6iGKRdhETuKAq5aOFQOm', 'cus_UJGeDrdQDfghvZ'),
        ('sub_1TKhpbGKRdhETuKAnNqGJWZ1', 'cus_UJKU9rDVA7ueRI'),
        ('sub_1TKoSvGKRdhETuKAILAyhR9C', 'cus_UJRLYFjWZI3gEB'),
        ('sub_1TL9HiGKRdhETuKARonz1WP6', 'cus_UJmrgAkNVUzUUr'),
        ('sub_1TLTZIGKRdhETuKAPzK6whtO', 'cus_UK7oDTfWmy01Ux'),
        ('sub_1TLWVqGKRdhETuKAiWjtfwPx', 'cus_UKArptXCg2SFGE'),
        ('sub_1TLZqaGKRdhETuKALCx7BqCy', 'cus_UKEJTKgUrPi8Pp'),
        ('sub_1TLcSzGKRdhETuKAbt5LIlXr', 'cus_UKH1XK6PV5EtuT'),
        ('sub_1TO7rTGKRdhETuKAeIeh2JJD', 'cus_UMraMpxW0REoSr'),
        ('sub_1TOzmwGKRdhETuKAmxkX4WDt', 'cus_UNlJocBAhkwuik'),
        ('sub_1TQAhNGKRdhETuKAMYDmlaeL', 'cus_UOyeoOSBhquo6E'),
        ('sub_1TQI9PGKRdhETuKA7mL2taPt', 'cus_UP6MBk1U7bP2ZP'),
        ('sub_1TQhUVGKRdhETuKAzvrR22WZ', 'cus_UPWX8qDERQp2la'),
        ('sub_1TRIMxGKRdhETuKA8gOcObMQ', 'cus_UQ8eHAD8rbCoNB'),
        ('sub_1TRNnjGKRdhETuKAPc9IXVdQ', 'cus_UQEGrsCRKep2ow'),
        ('sub_1TS35GGKRdhETuKAXR8bEbqk', 'cus_UQuvYyIGEbUOX6'),
        ('sub_1TS6BCGKRdhETuKAmWmFFhCf', 'cus_UQy7nkoPn6Abek'),
        ('sub_1TSLqBGKRdhETuKA5vxVKibM', 'cus_UREIDp1BWtKHvE'),
        ('sub_1TTduDGKRdhETuKAeTXVnZY5', 'cus_USZ2qfvXGUIJh7')
      ) AS m(sub_id, cus_id)
      WHERE bi.last_stripe_subscription_id = m.sub_id;
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      ADD COLUMN current_period_end TIMESTAMP WITH TIME ZONE,
      ADD COLUMN stripe_status TEXT
        CHECK (stripe_status IS NULL OR stripe_status IN
          ('active', 'trialing', 'past_due', 'unpaid',
           'canceled', 'incomplete', 'incomplete_expired'));
    """)

    try await sql.execute("""
      UPDATE parent.subscriptions
      SET
        stripe_status = CASE billing_status::TEXT
          WHEN 'paid'              THEN 'active'
          WHEN 'overdue'           THEN 'past_due'
          WHEN 'trialing'          THEN 'trialing'
          WHEN 'trialExpiringSoon' THEN 'trialing'
        END,
        current_period_end = status_expires_at - INTERVAL '2 days',
        updated_at = NOW()
      WHERE billing_status::TEXT IN
        ('paid', 'overdue', 'trialing', 'trialExpiringSoon')
        AND stripe_id IS NOT NULL;
    """)

    try await sql.execute("""
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM parent.billing_identities
          WHERE last_stripe_subscription_id IS NOT NULL
            AND stripe_customer_id IS NULL
        ) THEN
          RAISE EXCEPTION 'gap detected: identity rows with last_stripe_subscription_id but no stripe_customer_id — regenerate VALUES block (claude.report.plan.md §1.0) and redeploy';
        END IF;
      END $$;
    """)

    try await sql.execute("""
      ALTER TABLE parent.billing_identities
      ADD CONSTRAINT complimentary_has_no_stripe_state
        CHECK (is_complimentary = false OR last_stripe_subscription_id IS NULL),
      ADD CONSTRAINT customer_id_required_when_history_present
        CHECK (last_stripe_subscription_id IS NULL OR
               stripe_customer_id IS NOT NULL),
      ADD CONSTRAINT last_paid_tier_set_iff_history_present
        CHECK ((last_paid_tier IS NULL) =
               (last_stripe_subscription_id IS NULL));
    """)

    try await sql.execute("""
      CREATE UNIQUE INDEX billing_identities_stripe_customer_id_unique
        ON parent.billing_identities (stripe_customer_id)
        WHERE stripe_customer_id IS NOT NULL;
    """)

    try await sql.execute("""
      ALTER TABLE system.stripe_events
      ADD COLUMN stripe_event_id TEXT;
    """)

    try await sql.execute("""
      WITH first_per_event_id AS (
        SELECT DISTINCT ON ((json::JSONB)->>'id')
          id
        FROM system.stripe_events
        WHERE (json::JSONB) ? 'id'
        ORDER BY (json::JSONB)->>'id', created_at, id
      )
      UPDATE system.stripe_events AS se
      SET stripe_event_id = (se.json::JSONB)->>'id'
      FROM first_per_event_id AS chosen
      WHERE se.id = chosen.id;
    """)

    try await sql.execute("""
      ALTER TABLE system.stripe_events
      ADD CONSTRAINT stripe_events_event_id_unique UNIQUE (stripe_event_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE system.stripe_events
      DROP CONSTRAINT IF EXISTS stripe_events_event_id_unique;
    """)

    try await sql.execute("""
      ALTER TABLE system.stripe_events DROP COLUMN IF EXISTS stripe_event_id;
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      DROP CONSTRAINT IF EXISTS subscriptions_parent_in_billing_identities;
    """)

    try await sql.execute("""
      ALTER TABLE parent.subscriptions
      DROP COLUMN IF EXISTS current_period_end,
      DROP COLUMN IF EXISTS stripe_status;
    """)

    try await sql.execute("""
      DROP TABLE IF EXISTS parent.billing_identities;
    """)
  }
}
