# Product Scope and Mechanics Decision Record

## Public Release Purpose

This document defines the independently developed product scope used by the Merchant Sales-Based Financing Strategy Simulator. All assumptions are synthetic and exist to support deterministic portfolio architecture, evidence, and strategy testing without PII or production policy.

## Product Scope

The platform models short-duration merchant financing tied to point-of-sale activity and sales-linked repayment. A merchant receives a synthetic advance and a governed percentage of eligible daily sales is applied to repayment.

The architecture supports synthetic one-, two-, and three-month payoff horizons while retaining parameter-driven duration rather than hard-coding one product term.

## Core Mechanics

- merchant-level application and requested funding structure;
- daily POS sales and processor settlement evidence;
- sales-linked remittance rather than conventional monthly billing;
- processor continuity, settlement timing, and cash-flow volatility;
- deposit liquidity, obligations, affordability, and residual capacity;
- collateral, guarantee, covenant, and recovery evidence boundaries;
- scenario-aware risk, exposure, loss, and unit economics;
- acquisition source, campaign attribution, incurred cost, and conditional partner or broker cost;
- immutable latest/archive contracts and end-to-end G2 assurance;
- future pricing, offer, approval, counteroffer, review, decline, and portfolio-allocation logic reserved for Module 2.

## Strategic Horizon

The intended capability evolves from controlled launch and daily evidence to relationship management, dynamic exposure, renewal, loss mitigation, portfolio optimization, and multi-generational strategy learning.

## Interpretation Boundary

This record does not describe a client engagement or production product. It does not assert market terms, legal classification, regulatory applicability, accounting treatment, calibrated risk parameters, or operational readiness.
