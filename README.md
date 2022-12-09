# react-native-appmetrica

React Native bridge to the [AppMetrica](https://appmetrica.yandex.com/) on both iOS and Android.

## Installation

1. добавить в package.json
   "@odva/react-native-appmetrica": "git+https://github.com/odvapro/react-native-appmetrica.git",
2. iOS only `npx pod-install`

## Usage

```js
import AppMetrica from "@odva/react-native-appmetrica";

// Starts the statistics collection process.
AppMetrica.activate({
  apiKey: "...KEY...",
  sessionTimeout: 120,
  firstActivationAsUpdate: false,
});

// Sends a custom event message and additional parameters (optional).
AppMetrica.reportEvent("My event");
AppMetrica.reportEvent("My event", { foo: "bar" });

// Send a custom error event.
AppMetrica.reportError("My error");

//Send a ECommerce Event
AppMetrica.reportECommerce("checkout", (attributes = ECommerceObject));

interface ECommerceObject {
  screen: {
    screenName: "MyScreenName",
  };
  productsInfo: Product[];
  orderId: String;
}

interface Product {
  price: {
    price: number,
    typeOfCurrency: String,
  };
  product: {
    article: String,
    name: String,
    categoryName: String,
  };
  quantity: number;
}
```
