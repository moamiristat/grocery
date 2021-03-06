# Load packages
library(grocerycart)

##### Source analysis files -----
source(here::here("analysis/eg_analysis.R"))
source(here::here("analysis/oc_analysis.R"))
source(here::here("analysis/basket_analysis.R"))

##### Generate extra data -----
data("eg_store")
data("eg_product")
data("eg_data")
data("oc_data")

### store
# prob of ordering from each store according the the # of products in store
# more product ---> higher probability to select store
store_prob <-
  eg_data %>%
  dplyr::left_join(eg_store, by = "store_name") %>%
  dplyr::group_by(store_name) %>%
  dplyr::summarise(products = dplyr::n()) %>%
  dplyr::mutate(probs = products / sum(products)) %>%
  dplyr::arrange(desc(products))

### basket_db
# num of unique products, across all stores
eg_num_of_products <-
  eg_product %>%
  dplyr::distinct(item) %>%
  nrow()

# give random score for each product for probability calculation
eg_scores <-
  sample(1:39, size = eg_num_of_products, replace = TRUE) %>%
  tibble::tibble(score = .) %>%
  dplyr::bind_cols(eg_product %>% dplyr::distinct(item, .keep_all = TRUE)) %>%
  dplyr::rename("product" = item) %>%
  dplyr::select(product, price, score)

# prob of ordering a product is based on num of reviews + % recommend
oc_scores <-
  oc_data %>%
  dplyr::group_by(product) %>%
  dplyr::summarise(product = product,
                   price = price,
                   score = ceiling((as.numeric(num_of_reviews) + as.numeric(recommend)) * .5)) %>%
  dplyr::filter(!is.na(score)) %>%
  dplyr::ungroup()

product_prob <-
  oc_scores %>%
  dplyr::bind_rows(eg_scores) %>%
  dplyr::mutate(probs = score / sum(score)) %>%
  dplyr::arrange(desc(score))

### Payment method
# 70% use online payment
# 20% pay with credit card on delivery
# 10% pay with cash on delivery
eg_payment_method <-
  tibble::tibble(
    method = c("Online Payment", "Credit Card on delivery", "Cash on delivery"),
    prob = c(.7, .2, .1)
  )

# ### For 1 store (funmart): 100 products with random probabilities
# product_prob_funmart <-
#   tibble::tibble(
#     product = sample(product_prob$product, size = 200, replace = FALSE)) %>%
#   dplyr::mutate(probs = probs(j = 200))

data("basket_db_funmart")

grocery <- 
  basket_db_funmart %>% 
  distinct(basket_id, product)

products_available <- 
  grocery  %>% 
  select(product) %>% 
  unique() %>% 
  arrange(product)
