## publish

```
sui client publish --gas-budget 30000 --dev
```

## call function

price feed

```
sui client call \
--function test_price_feed \
--module price \
--package 0xaaae0d082b7959d5919f578bc1990464c6d1339e \
--args 0xc9b7b0d3aa42237e76d1af758a7bb90215e70569 \
--type-args 0x33e5b1bafadeca4c678f7bae6cea3d326a44a02a::btc::BTC \
--gas-budget 3000
```

time feed

```
sui client call \
--function test_time_feed \
--module timestamp \
--package 0xfb24275a036126efc43bde90b4180c12dbd9b912 \
--args 0xd150885f3308ff2c6d1d5c0e7dbf1ed369cf42c3 \
--gas-budget 3000
```
