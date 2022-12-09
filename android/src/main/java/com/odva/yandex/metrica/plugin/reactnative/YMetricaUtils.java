package com.odva.yandex.metrica.plugin.reactnative;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.yandex.metrica.YandexMetrica;
import com.yandex.metrica.ecommerce.ECommerceAmount;
import com.yandex.metrica.ecommerce.ECommerceCartItem;
import com.yandex.metrica.ecommerce.ECommerceEvent;
import com.yandex.metrica.ecommerce.ECommerceOrder;
import com.yandex.metrica.ecommerce.ECommercePrice;
import com.yandex.metrica.ecommerce.ECommerceProduct;
import com.yandex.metrica.ecommerce.ECommerceReferrer;
import com.yandex.metrica.ecommerce.ECommerceScreen;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class YMetricaUtils {
    String type;
    ReadableMap options;

    public YMetricaUtils(String type, ReadableMap options){
        this.type=type;
        this.options=options;
    }

    private List<ECommerceCartItem> getCartItemsList(ECommerceReferrer referrer, ReadableArray array) {
        List<ECommerceCartItem> list = new ArrayList<>();
        for (int i = 0; i < array.size(); i++) {
            ReadableMap itemMap = array.getMap(i);
            ECommerceCartItem item = getECommerceCartItem(referrer, itemMap);
            list.add(item);
        }
        return list;
    }

    private ECommerceCartItem getECommerceCartItem(ECommerceReferrer referrer, ReadableMap options) {
        ReadableMap priceMap = options.getMap("price");
        ECommercePrice actualPrice = getECommercePrice(priceMap);

        ReadableMap productMap = options.getMap("product");
        ECommerceProduct product = getECommerceProduct(actualPrice, productMap);

        Double quantity = options.getDouble("quantity") * 1.0;
        ECommerceCartItem addedItems = new ECommerceCartItem(product, actualPrice, quantity)
                .setReferrer(referrer);
        //Создаем ивент добавления в корзину
        ECommerceEvent eCommerceEvent = ECommerceEvent.addCartItemEvent(addedItems);
        //Отправляем в метрику
        YandexMetrica.reportECommerce(eCommerceEvent);

        return addedItems;
    }

    public void reportECommerse(){
        if (this.type.equals("checkout")){
            reportCheckout(this.options);
        }
    }

    private void reportCheckout(ReadableMap options) {

        ReadableMap screenMap = options.getMap("screen");
        if (screenMap == null) return;
        ECommerceScreen screen = getECommerceScreen(screenMap);
        ECommerceReferrer referrer = new ECommerceReferrer()
                .setScreen(screen);


        ReadableArray items = options.getArray("productsInfo");
        if (items == null) return;
        List<ECommerceCartItem> list = getCartItemsList(referrer, items);

        //создать заказ, прикрепить к нему номер заказа и массив товаров
        String orderId = options.getString("orderId");
        if (orderId == null) orderId = "123456";
        ECommerceOrder order = new ECommerceOrder(orderId, list);
        //создаем ивент начала покупки
        ECommerceEvent beginCheckoutEvent = ECommerceEvent.beginCheckoutEvent(order);
        YandexMetrica.reportECommerce(beginCheckoutEvent);

        //создаем ивент оплаты
        ECommerceEvent purchaseEvent = ECommerceEvent.purchaseEvent(order);
        YandexMetrica.reportECommerce(purchaseEvent);
    }


    private ECommerceScreen getECommerceScreen(ReadableMap options) {
        return new ECommerceScreen().
                setName(options.getString("screenName"));
    }

    private ECommercePrice getECommercePrice(ReadableMap options) {
        Double price = options.getDouble("price");
        String type = options.getString("typeOfCurrency");
        if (type == null) type = "RUB";
        ECommerceAmount amount = new ECommerceAmount(price, type);
        return new ECommercePrice(amount);
    }

    private ECommerceProduct getECommerceProduct(ECommercePrice price, ReadableMap options) {
        String article = options.getString("article");
        if (article.isEmpty()) article = "000000";
        String name = options.getString("name");
        if (name.isEmpty()) name = "Нет имени";
        String categoryName = options.getString("categoryName");
        if (categoryName.isEmpty()) categoryName = "1234";
        return new ECommerceProduct(article)
                .setActualPrice(price)
                .setOriginalPrice(price)
                .setName(name)
                .setCategoriesPath(Collections.singletonList(categoryName));
    }


    private void reportAddCart(ReadableMap options) {

        ECommerceScreen screen = getECommerceScreen(options.getMap("screen"));
        ECommercePrice actualPrice = getECommercePrice(options.getMap("price"));
        ECommerceProduct product = getECommerceProduct(actualPrice, options.getMap("product"));
        ECommerceReferrer referrer = new ECommerceReferrer()
                .setScreen(screen);
        ECommerceCartItem addedItems = new ECommerceCartItem(product, actualPrice, options.getDouble("quantity"))
                .setReferrer(referrer);
        ECommerceEvent eCommerceEvent = ECommerceEvent.addCartItemEvent(addedItems);
        YandexMetrica.reportECommerce(eCommerceEvent);
    }
}