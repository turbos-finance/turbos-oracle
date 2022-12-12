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
--package 0x1c0fe71a65fb991f8e03a67c2059861f26ec765e \
--args 0x0fee5c8f5f36bd88f03d6d09823f5d0c35055f1d \
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
