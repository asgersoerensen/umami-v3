# Umami - Meal Planning to Grocery Cart

**Tagline:** From recipes to checkout in 3 minutes instead of 30

**Status:** Pre-MVP concept validation phase  
**Target Market:** Denmark (initial launch)  
**Founder:** Asger (Product Manager + Developer at Liva Healthcare)

---

## Problem Statement

### The Pain Point
Parents and busy families waste 20-30 minutes weekly converting their meal plans into online grocery carts. The process is tedious:
1. Find recipes online
2. Extract ingredients from each recipe
3. Open grocery website
4. Search for each ingredient (30+ searches)
5. Scroll through dozens of SKU variations
6. Add wrong item, go back, search again
7. Repeat for every ingredient
8. Finally checkout

**Additional pain:** For physical shoppers, disorganized shopping lists lead to wandering around stores inefficiently.

### Current Alternatives
- **Meal kit services** (HelloFresh, Blue Apron): Expensive, inflexible, can't use your own recipes
- **Recipe apps** (Paprika, Mealime): Generate shopping lists but don't integrate with grocers
- **Manual process**: Notes app + grocery website (current state for most users)
- **Grocery apps**: Have meal planning features but limited to their own recipe databases

### Why Now?
1. **LLMs enable reliable recipe extraction** from arbitrary websites (wasn't feasible 3 years ago)
2. **Unofficial APIs exist** for Danish grocers (Nemlig validated)
3. **Post-COVID online grocery adoption** has normalized the behavior
4. **Ingredient consolidation** is now solvable with AI (matching across different formats/units)

---

## Solution

### Core Value Proposition
**"Paste your recipe links, get a complete grocery cart ready for checkout in 3 minutes"**

### How It Works

#### For Online Shoppers (Primary Product)
1. User finds recipes they want to cook this week (from any website)
2. Pastes recipe URLs into Umami
3. Assigns recipes to days in meal planning calendar
4. Clicks "Build Cart"
5. Umami:
   - Extracts ingredients from all recipes
   - Consolidates duplicate ingredients
   - Matches to grocery store SKUs
   - Auto-fills cart at their chosen grocer (Nemlig initially)
6. User reviews cart, makes any adjustments, checks out
7. **Time saved: 25+ minutes per week**

#### For Physical Shoppers (Secondary Product)
1. Same recipe import + meal planning
2. Generates shopping list sorted by store layout
3. User prints/views on phone while shopping
4. **Benefit:** Efficient in-store navigation

### Key Features

**MVP (Months 1-3):**
- Recipe URL import (paste or browser extension)
- LLM-powered ingredient extraction
- Ingredient consolidation across recipes
- Weekly meal planning calendar
- Nemlig.com cart auto-fill
- Basic SKU matching (with manual review capability)

**Post-MVP (Months 4-6):**
- Multiple grocer support (Coop, Føtex, Rema 1000)
- Smart SKU selection (learns user preferences)
- Price comparison across grocers
- Pantry tracking (reduce duplicate purchases)
- Recipe discovery (based on sale items, seasons)

**Future Features (Months 6+):**
- Automated pantry management via receipt scanning
- Food waste reduction (recipes based on expiring items)
- Dietary restriction filters
- Family preference learning
- Nutrition tracking
- Budget optimization

---

## Target Customer

### Primary Persona: "Marie"
- **Age:** 35-45
- **Family:** 2-3 kids (ages 4-12)
- **Employment:** Dual-income household, both work full-time
- **Shopping:** Online grocery delivery 2-3x/month (Nemlig or Coop)
- **Pain:** Sunday evening meal planning takes 1+ hour, frustrating
- **Tech savvy:** Uses iPhone, comfortable with apps
- **Budget:** Middle to upper-middle class, willing to pay for convenience
- **Values:** Time savings, reducing food waste, family health

### Secondary Persona: "Thomas"
- **Age:** 28-35
- **Family:** Young couple or single parent
- **Employment:** Professional, time-constrained
- **Shopping:** Weekly Føtex/Bilka run
- **Pain:** Inefficient store navigation with messy lists
- **Tech savvy:** Early adopter
- **Budget:** Price-conscious but values efficiency

### Market Size (Denmark)
- ~2M households
- ~500K shop online for groceries regularly
- Target: 5% penetration = 25K users
- At 10% conversion to premium = 2,500 paying users
- At 99 DKK/month = ~250K DKK/month = 3M DKK ARR

---

## Business Model

### Revenue Streams

**Primary: Subscription (B2C)**
- **Freemium tier:**
  - Recipe import + ingredient consolidation
  - Basic shopping list export
  - 3 auto-cart builds per month
  
- **Premium tier (99 DKK/month):**
  - Unlimited auto-cart builds
  - Multi-grocer support
  - Smart SKU preferences
  - Pantry tracking
  - Price comparison
  - Premium recipe collections

**Secondary: Commission (B2B2C - Long-term)**
- Partner with grocers for revenue share on orders
- Requires traction first (1000+ users)
- 2-5% commission on incremental basket value
- Only pursue after PMF validation

### Unit Economics (Target)
- **CAC (Customer Acquisition Cost):** 200 DKK (Facebook ads, word-of-mouth)
- **LTV (Lifetime Value):** 99 DKK/mo × 12 months avg retention = 1,188 DKK
- **LTV:CAC ratio:** ~6:1 (healthy)
- **Gross margin:** 85% (software business, minimal COGS)
- **Breakeven:** ~300 paying users (30K DKK MRR to cover hosting + minimal ops)

---

## Technical Architecture

### Tech Stack (Recommended)

**Frontend:**
- **Mobile app:** React Native using expo

**Backend:**
- **API:** Django
- **Database:** PostgreSQL
- **LLM:** Anthropic Claude API (Sonnet for cost/performance balance)
- **Task queue:** BullMQ/Redis for async processing

**Integrations:**
- **Grocery APIs:** Unofficial Nemlig API (via reverse-engineering)
  - Reference: https://github.com/schourode/nemlig
  - Risk: Could break, no SLA, legal gray area
  - Mitigation: Browser extension fallback
- **Recipe scraping:** 
  - Tier 1: Schema.org JSON-LD parsing (safest)
  - Tier 2: HTML parsing with Cheerio/BeautifulSoup
  - Tier 3: Browser extension client-side extraction

**Infrastructure:**
- **Payments:** Stripe (subscription billing)
- **Analytics:** PostHog or Mixpanel (product analytics)
- **Monitoring:** Sentry (error tracking)
- **Email:** SendGrid or Postmark (transactional emails)

### Data Model (Core Entities)

```
User
├── email, password_hash, stripe_customer_id
├── preferences (dietary restrictions, preferred grocers, budget)
└── subscription_tier (free/premium)

Recipe
├── url, title, source_website
├── ingredients[] (raw extracted text)
├── parsed_ingredients[] (structured: item, quantity, unit)
├── instructions, prep_time, servings
└── user_id (who saved it)

MealPlan
├── user_id, week_start_date
└── meals[] (recipe_id, day, meal_type)

ShoppingList
├── meal_plan_id
├── consolidated_ingredients[]
└── grocer_cart_data (matched SKUs)

GroceryItem (Nemlig catalog cache)
├── sku, name, brand, price
├── category, subcategory
├── unit_size, unit_type
└── last_updated
```

### Key Technical Challenges

**1. Ingredient Extraction & Normalization**
- **Challenge:** Recipes use inconsistent formats
  - "1 cup diced tomatoes"
  - "400g tin chopped tomatoes"  
  - "2 large tomatoes, chopped"
- **Solution:** LLM prompt engineering + structured output
  - Extract: item, quantity, unit, preparation
  - Normalize units (cups → ml, oz → g)
  - Handle ranges ("2-3 tomatoes")

**2. SKU Matching**
- **Challenge:** Map "tomatoes, chopped, 400g" to specific Nemlig SKU
  - 47 tomato products in catalog
  - Fresh vs canned vs crushed vs whole
  - Organic vs conventional
  - Brand preferences
- **Solution:** 
  - Multi-factor matching (keyword, category, size, price tier)
  - User preference learning (remember brand choices)
  - Confidence scoring (flag uncertain matches)
  - Manual override UI

**3. Ingredient Consolidation**
- **Challenge:** Combine across recipes
  - Recipe 1: "200g pasta"
  - Recipe 2: "300g spaghetti"
  - Should these consolidate to "500g pasta" or separate items?
- **Solution:**
  - LLM-based similarity detection
  - User confirmation for ambiguous cases
  - Smart bundling (1kg bag vs 2x 500g)

**4. Grocery API Reliability**
- **Challenge:** Unofficial API could break anytime
- **Solution:**
  - Version detection + automated tests
  - Graceful degradation (export to clipboard)
  - Browser extension fallback
  - Monitor API health daily

**5. Authentication & Security**
- **Challenge:** Need user's Nemlig credentials to place orders
- **Solution (Phase 1 - Browser Extension):**
  - Extension reads session cookies locally
  - No credential storage on servers
  - User stays logged in to Nemlig
- **Solution (Phase 2 - Server-side):**
  - Encrypted credential storage (AES-256)
  - Transparent security messaging
  - Optional "local-only mode"

---

## Legal & Risk Mitigation

### Recipe Scraping Legality

**Approach: User-initiated scraping as user agent**
- ✅ User pastes URL → single fetch (like a browser)
- ✅ Extract structured data (Schema.org when available)
- ✅ Store only ingredients/quantities (facts, not copyrightable)
- ✅ Always link back to original recipe
- ❌ Never bulk scrape entire sites
- ❌ Never republish full recipe text/photos

**Legal protections:**
- Respect robots.txt
- Clear User-Agent: "Umami/1.0 (meal planning app)"
- Opt-out mechanism for site owners
- Terms of Service: users represent they have right to import
- Attribution + backlinks (drives traffic to recipe sites)

**Precedent:**
- Pocket, Instapaper (save articles for later)
- Paprika, Mealime (recipe import apps)
- Pinterest (scrapes content when user pins)
- All operate for years without major legal issues

**Risk level: LOW** - You're helping recipe sites (traffic generation), not competing

### Grocery API Usage

**Challenge:** Using unofficial Nemlig API
- No SLA, could break anytime
- Potential ToS violation
- IP blocking risk

**Risk mitigation:**
1. **Start with browser extension** (user's browser, user's credentials)
2. **Respectful usage** (rate limits, no abuse)
3. **Value creation** (generating real orders for Nemlig)
4. **Path to partnership** (approach with traction data later)

**Precedent:**
- Mint (scraped banks before official partnerships)
- Plaid (reverse-engineered bank APIs, now $13B company)
- Many successful startups started "unofficial"

**Strategy:** Build on unofficial API → get traction → negotiate official partnership

---

## Go-to-Market Strategy

### Phase 1: Validation (Weeks 1-4)
**Goal:** Prove people will actually use this

**Tactics:**
1. Build minimal scraper + LLM consolidation
2. Manual cart building (you do it for users)
3. Recruit 10 friends/family who shop online
4. Time how long manual vs. automated takes
5. **Success criteria:** 8/10 say "I'd pay for this"

**Budget:** 0 DKK (your time only)

### Phase 2: MVP Beta (Weeks 5-12)
**Goal:** 50 beta users, 10 paying

**Product:**
- Web app (mobile-first)
- Recipe import + meal planning
- Nemlig cart auto-fill
- Basic freemium paywall

**User acquisition:**
- Facebook groups (Danish parenting, meal planning)
- Reddit r/Denmark
- Personal network
- Free during beta, ask for feedback

**Success criteria:**
- 50 signups
- 30 active weekly users
- 10 pay 49 DKK/month (beta pricing)
- <5 min cart build time
- >85% SKU matching accuracy

**Budget:** 5-10K DKK (hosting, domain, ads)

### Phase 3: Early Growth (Months 4-6)
**Goal:** 100 paying users (10K MRR)

**Product improvements:**
- Add Coop/Føtex integration
- Improve SKU matching accuracy
- Pantry tracking
- Price to 99 DKK/month

**User acquisition:**
- Facebook/Instagram ads (target: Nemlig + madplan keywords)
- Content marketing (blog posts on meal planning efficiency)
- Referral program (invite 3 friends → 1 month free)
- PR pitch to Danish parenting media

**Success criteria:**
- 100 paying users
- 50% week-2 retention
- 30% conversion free → paid
- <10% churn monthly

**Budget:** 20-30K DKK (ads, tools, contractor help)

### Phase 4: Scale (Months 7-12)
**Goal:** 500 paying users (50K MRR)

**Tactics:**
- Approach Nemlig for official partnership
- Expand to more grocers
- Add recipe discovery features
- Build referral loops into product

---

## Competitive Analysis

### Direct Competitors (Denmark)
**Need to research:** Are there existing Danish meal planning + grocery integration apps?

**Search:**
- Danish App Store: "madplan", "indkøbsliste"
- Google: "madplanlægning app Danmark"
- Facebook groups for existing solutions
- Trustpilot reviews of Nemlig (what do people wish existed?)

### Indirect Competitors

**Meal Kit Services:**
- HelloFresh, Simple Feast, RetNemt
- **Strength:** Zero effort, pre-portioned
- **Weakness:** Expensive (100+ DKK/serving), inflexible, can't use own recipes
- **Your advantage:** Flexibility, cost (regular grocery prices), own recipe choice

**Recipe Apps:**
- Paprika, Mealime, Yummly
- **Strength:** Good recipe management
- **Weakness:** No grocery integration (you still manually shop)
- **Your advantage:** End-to-end solution

**Grocery Apps:**
- Nemlig, Coop Mad, Føtex
- **Strength:** Integrated shopping experience
- **Weakness:** Limited to their recipe databases, clunky meal planning
- **Your advantage:** Any recipe from anywhere

### Competitive Moat

**12-18 month window:**
- LLM integration (non-trivial to implement)
- Multi-grocer catalog integration
- User preference learning (gets better over time)

**Long-term defensibility:**
- User data (preferences, pantry, shopping patterns)
- Network effects (recipe sharing, meal planning templates)
- Exclusive grocer partnerships (once you have leverage)

**Risk:** If successful, grocers or recipe platforms could copy. Need to move fast.

---

## Success Metrics

### North Star Metric
**Minutes saved per user per week** (target: 20+ minutes)

### Key Metrics by Phase

**Validation (Weeks 1-4):**
- 10 test users complete 1 week of meal planning
- 8/10 say they'd pay
- Average time: <5 min cart build

**MVP Beta (Weeks 5-12):**
- 50 signups
- 60% activation (complete first meal plan)
- 40% week-2 retention
- 10 paying users

**Early Growth (Months 4-6):**
- 100 paying users (10K MRR)
- 50% week-2 retention, 30% week-4 retention
- <10% monthly churn
- 85%+ SKU match accuracy
- 4.0+ App Store rating

**Scale (Months 7-12):**
- 500 paying users (50K MRR)
- 60% week-2 retention, 40% month-3 retention
- <7% monthly churn
- 30% free → paid conversion
- Referral rate: 15% of users invite friends

---

## Timeline & Milestones

### Weeks 1-2: Technical Validation
- [ ] Fork Nemlig API repo, test current state
- [ ] Build recipe scraper (5 popular Danish sites)
- [ ] LLM ingredient extraction POC
- [ ] Manual consolidation + cart link generation
- [ ] **Deliverable:** Python script (recipe URLs → Nemlig cart URL)

### Weeks 3-4: Wizard of Oz Test
- [ ] Simple web form for recipe submission
- [ ] Recruit 10 test users (friends/family)
- [ ] Manually review LLM output, generate carts
- [ ] Measure time saved
- [ ] **Go/No-Go decision:** Do 8/10 say they'd pay?

### Weeks 5-8: MVP Development
- [ ] Next.js web app (mobile-first)
- [ ] Recipe import + URL paste
- [ ] Meal planning calendar UI
- [ ] Nemlig API integration (automated)
- [ ] Basic SKU matching algorithm
- [ ] **Deliverable:** Functional app (invite-only)

### Weeks 9-10: Beta Launch
- [ ] Recruit 50 beta users (Facebook, Reddit)
- [ ] Free access, feedback collection
- [ ] Monitor: completion rate, accuracy, bugs
- [ ] **Metric:** 60% activation, 40% week-2 retention

### Weeks 11-12: Monetization
- [ ] Add paywall (3 free/month, 99 DKK unlimited)
- [ ] Stripe integration
- [ ] Pricing page + checkout flow
- [ ] **Target:** 10 paying users

### Months 4-6: Product-Market Fit
- [ ] Add Coop/Føtex integrations
- [ ] Improve SKU matching (user feedback loop)
- [ ] Pantry tracking feature
- [ ] Referral system
- [ ] **Target:** 100 paying users, 10K MRR

### Months 7-12: Growth
- [ ] Approach Nemlig for official partnership
- [ ] Recipe discovery features
- [ ] Advanced pantry management
- [ ] Mobile app (iOS/Android if needed)
- [ ] **Target:** 500 paying users, 50K MRR

---

## Open Questions & Next Steps

### Critical Unknowns (Need Validation)

**1. Grocery API Access**
- [ ] Test current Nemlig API functionality
- [ ] Identify which endpoints are needed (search, cart, checkout)
- [ ] Determine if full checkout automation is possible
- [ ] **Risk:** If API doesn't support checkout, only cart building

**2. Recipe Site Landscape**
- [ ] List top 20 Danish recipe sites by traffic
- [ ] Check which use Schema.org markup
- [ ] Test scraping on 5-10 sites
- [ ] **Risk:** If most don't have structured data, parsing is fragile

**3. SKU Matching Feasibility**
- [ ] Build test harness: 50 ingredients → Nemlig SKUs
- [ ] Measure accuracy (target: 85%+)
- [ ] Identify failure patterns (fresh vs frozen, brands)
- [ ] **Risk:** If accuracy <80%, users won't trust it

**4. Competitive Landscape**
- [ ] Thorough search for existing Danish solutions
- [ ] Interview target users: what do they use now?
- [ ] **Question:** If nobody's doing this, why not?

**5. User Willingness to Pay**
- [ ] Survey target users on current pain + willingness to pay
- [ ] Test pricing: 49, 79, or 99 DKK/month?
- [ ] **Question:** What's the perceived value of 20 min saved/week?

### Immediate Next Actions (This Week)

**Day 1-2:**
1. Clone and test Nemlig API (schourode repo)
2. Verify cart building + checkout capabilities
3. Document API endpoints and authentication flow

**Day 3-4:**
4. Build recipe scraper POC (test on 5 Danish sites)
5. LLM prompt for ingredient extraction (test with Claude)
6. Test consolidation across 3-4 recipes

**Day 5-7:**
7. Create minimal web form for user testing
8. Recruit 5 test users from personal network
9. Manual cart building test (measure time saved)

**Week 2 Decision Point:**
- **If time savings >15 min AND 4/5 users interested:** Proceed to MVP build
- **If not:** Reassess value prop or pivot

---

## Budget & Resources

### Development (Self + Potential Contractors)
- **Your time:** 15 hrs/week (nights/weekends)
- **Timeline:** 12 weeks to paying MVP
- **Contractor help (optional):** 10-20K DKK for design/mobile app

### Tools & Services (Monthly)
- Hosting (Vercel/Supabase): 200 DKK
- Domain + email: 50 DKK
- Anthropic API (Claude): 300-500 DKK (scales with usage)
- Stripe fees: 1.9% + 1.80 DKK per transaction
- Analytics (PostHog): Free tier initially
- **Total:** ~600 DKK/month initially, scales with users

### Marketing (One-time + Ongoing)
- Beta recruitment ads: 2-5K DKK
- Landing page design: 3-5K DKK (or DIY)
- Growth ads (Months 4-6): 10-20K DKK
- **Total Year 1:** 20-30K DKK

### Total Investment (12 months)
- Development: Your time (sweat equity)
- Tools: ~10K DKK
- Marketing: ~25K DKK
- **Total cash needed:** 35-40K DKK

**Breakeven:** ~300 paying users at 99 DKK/month = 30K MRR

---

## Decision Criteria

### When to Go Full-Time
**Signals:**
- 100+ paying users (10K+ MRR)
- <10% monthly churn
- Clear path to 500 users (50K MRR)
- 3+ months of runway from revenue or savings

### When to Pivot
**Red flags:**
- Can't get 10 paying users in 3 months
- Churn >20% monthly
- SKU matching accuracy stuck <70%
- Grocery APIs get blocked with no workaround

### When to Shut Down
**Kill criteria:**
- Zero paying users after 6 months
- Technical blockers can't be solved
- Market research shows nobody cares
- Personal burnout / family impact too high

---

## Contact & Resources

**Founder:** Asger (Product Manager + Developer)  
**Location:** Copenhagen, Denmark  
**Background:** PM at Liva Healthcare, experience in SaaS, healthcare integrations, engineering process improvement

**Key References:**
- Nemlig API: https://github.com/schourode/nemlig
- Schema.org Recipe markup: https://schema.org/Recipe
- Similar apps: Paprika, Mealime, Yummly (international references)

**Next Review:** After Week 2 validation testing

---

*Last updated: March 16, 2026*
*Status: Pre-MVP concept validation*
