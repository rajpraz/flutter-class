/// Server-side sort options for paginated product queries. Each maps to a
/// distinct Firestore `orderBy`, so each needs its own composite index
/// alongside the `isActive == true` equality filter — see
/// firestore.indexes.json and the batch-2 report for which are already
/// defined vs. still need deploying.
enum ProductSort { newest, priceLowToHigh, priceHighToLow, popularity }
