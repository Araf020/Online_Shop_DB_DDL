create sequence ORDERID
	minvalue 1900000
	maxvalue 190000000000
/

create sequence PEOPLEID
	minvalue 1700000
	maxvalue 170000000000
/

create sequence SHIPMENTID
	minvalue 1600000
	maxvalue 160000000000
/

create sequence PRODUCTID
	minvalue 1500000
	maxvalue 150000000000
/

create sequence PAYMENTID
	minvalue 1400000
	maxvalue 140000000000
/

create sequence CATATAGORYID
	minvalue 1150000
	maxvalue 11500000000
/

create sequence SHOPID
	minvalue 1140000
	maxvalue 11400000000
/

create sequence DEMOID
	minvalue 1140000
/

create table PEOPLE
(
	CUSTOMER_ID NUMBER(15) not null
		constraint CUSTOMER_PK
			primary key,
	CUSTOMER_NAME VARCHAR2(50),
	CUSTOMER_PHOTO VARCHAR2(50),
	GENDER VARCHAR2(10),
	BIRTHDATE DATE,
	ADRESS VARCHAR2(200),
	ZONE VARCHAR2(50),
	EMAIL VARCHAR2(50)
		unique,
	ROLE VARCHAR2(30),
	KEY RAW(2000),
	CONTACT VARCHAR2(200),
	BILLING_ADDRESS VARCHAR2(500)
)
/

create table ORDERS
(
	ORDER_ID NUMBER not null
		constraint ORDER_PK
			primary key,
	CUSTOMER_ID NUMBER(15)
		constraint FK_ORDER
			references PEOPLE
				on delete cascade,
	ORDER_DATE DATE,
	AMOUNT NUMBER,
	QUANTITY NUMBER,
	PAYMENT_STATUS VARCHAR2(10)
)
/

create table CATAGORIES
(
	CAT_ID NUMBER not null
		constraint CAT_PK
			primary key,
	CAT_NAME VARCHAR2(50)
		constraint CATNAME_UK
			unique,
	QUANTITY NUMBER
)
/

create table SHOPS
(
	SHOP_ID NUMBER not null
		primary key,
	SHOP_NAME VARCHAR2(40),
	ZONE VARCHAR2(30),
	CONTACT_INFO VARCHAR2(100),
	SHOP_CAT VARCHAR2(100),
	SHOP_USERNAME VARCHAR2(100),
	SHOPKEY RAW(2000)
)
/

create table PRODUCTS
(
	PRODUCT_ID NUMBER not null
		constraint PRODUCT_PK
			primary key,
	PRODUCT_NAME VARCHAR2(100),
	CAT_ID NUMBER
		constraint FK_PRODUCT_CAT
			references CATAGORIES
				on delete cascade,
	STATUS VARCHAR2(50),
	PRICE NUMBER,
	DISCOUNT NUMBER,
	QUANTITY NUMBER,
	DESCRIPTION VARCHAR2(4000),
	SHOP_ID NUMBER
		constraint FK_PRODUCT_SHOP
			references SHOPS
				on delete cascade,
	BRAND VARCHAR2(100),
	PRODUCT_PHOTO VARCHAR2(1000)
)
/

create table PRODUCT_ORDERS
(
	ORDER_ID NUMBER
		constraint FK1
			references ORDERS
				on delete cascade,
	PRODUCT_ID NUMBER
		constraint FK2
			references PRODUCTS
				on delete cascade,
	constraint PRODUCT_ORDER_UNIQUNESS
		unique (ORDER_ID, PRODUCT_ID)
)
/

create trigger TRIGGER_FOR_DECREASE_QTY
	after insert
	on PRODUCT_ORDERS
	for each row
DECLARE
		Productid Number;
        OrderId number;
        qty1 number;
        oldqty number;
        newqty number;
        catid number;


BEGIN
        Productid := :NEW.PRODUCT_ID;
		OrderId := :NEW.ORDER_ID;
        select QUANTITY into qty1 from ORDERS where ORDERS.ORDER_ID = OrderId;
        select CAT_ID into catid from PRODUCTS where PRODUCT_ID = Productid;
        DECREASE_ITEMQTY(qty1,Productid);
        DECREASE_CATQTY(qty1,catid);

--         newqty := oldqty - qty1;
--         if newqty < 0 then
--             newqty :=0;
--         end if;
--         update PRODUCTS
--           set QUANTITY = newqty
--           where PRODUCTS.PRODUCT_ID = Productid;


exception
    WHEN too_many_rows THEN
        dbms_output.put_line('Errors fetching are more than one');

    when others then
        dbms_output.put_line('Unknown error occured!');

END;
/

create table PAYMENTS
(
	PAYMENT_ID NUMBER not null,
	ORDER_ID NUMBER not null
		unique
		constraint FK_PAYMENTS
			references ORDERS
				on delete cascade,
	PAYMENT_STATUS VARCHAR2(20),
	METHOD VARCHAR2(30),
	constraint PAYMENT_PK
		primary key (PAYMENT_ID, ORDER_ID)
)
/

create trigger TRIGGER_FOR_SHIPPING
	after insert
	on PAYMENTS
	for each row
DECLARE
        OrderId number;
        pay_method varchar2(50);
        pay_status varchar2(50);
        orderdate date;
        userid number;
        shipdate date;


BEGIN

		OrderId := :NEW.ORDER_ID;
		pay_method := :NEW.METHOD;
		pay_status := :NEW.PAYMENT_STATUS;
        select ORDER_DATE,CUSTOMER_ID into orderdate,userid from ORDERS where ORDERS.ORDER_ID = OrderId;
		shipdate := orderdate + 5;
		if LOWER(pay_status) = 'true' then
            INSERT into SHIPMENTS(shipment_id, shipment_date, order_id, status, deliveryat) VALUES (SHIPMENTID.nextval,shipdate,OrderId,'false',GETADDRESS(userid));
        else

            if lower(pay_method) = 'cash_on_delivery' then
            INSERT into SHIPMENTS(shipment_id, shipment_date, order_id, status, deliveryat) VALUES (SHIPMENTID.nextval,shipdate,OrderId,'false',GETADDRESS(userid));

            end if;

        end if;




exception
    WHEN too_many_rows THEN
        dbms_output.put_line('Errors fetching are more than one');

    when others then
        dbms_output.put_line('Unknown error occured!');

END;
/

create table SHIPMENTS
(
	SHIPMENT_ID NUMBER not null
		constraint SHIPMENT_PK
			primary key,
	SHIPMENT_DATE DATE,
	ORDER_ID NUMBER
		constraint UNIQUE_ORDER
			unique
		constraint FK_SHIP
			references ORDERS
				on delete cascade,
	STATUS VARCHAR2(20),
	DELIVERYAT VARCHAR2(500)
)
/

create table BKASH
(
	ACCNO NUMBER
		unique,
	OTP NUMBER,
	PIN NUMBER
)
/

create table CREDIT_CARD
(
	CARD_NO NUMBER
		unique,
	NAME_ON_CARD VARCHAR2(50),
	EXP_DATE DATE,
	CVV NUMBER,
	ZIP_CODE NUMBER
)
/

create PROCEDURE decrease_catQty
  ( qty          in number
   ,catid     in number

   )
IS
    oldqty number;
    newqty number;
BEGIN

  select QUANTITY into oldqty from CATAGORIES where CAT_ID = catid;

  DBMS_OUTPUT.PUT_LINE(oldqty);
  newqty := oldqty - qty;
  if newqty < 0 then
      newqty :=0;
  end if;
  update CATAGORIES
      set QUANTITY = newqty
    where CAT_ID = catid;

 exception
    WHEN too_many_rows THEN
        dbms_output.put_line('Errors fetching are more than one');

    when others then
        dbms_output.put_line('Unknown error occured!');


END decrease_catQty;
/

create PROCEDURE decrease_itemQty
  ( qty          in number
   ,itemid     in number

   )
IS
    oldqty number;
    newqty number;
BEGIN

  select QUANTITY into oldqty from PRODUCTS where PRODUCT_ID = itemid;

  DBMS_OUTPUT.PUT_LINE(oldqty);
  newqty := oldqty - qty;
  if newqty < 0 then
      newqty :=0;
  end if;
  update PRODUCTS
      set QUANTITY = newqty
    where PRODUCT_ID = itemid;

 exception
    WHEN too_many_rows THEN
        dbms_output.put_line('Errors fetching are more than one');

    when others then
        dbms_output.put_line('Unknown error occured!');


END decrease_itemQty;
/

create FUNCTION getAddress(userid number)
return Varchar2
IS
    billingadd varchar2(1000);


BEGIN
    select BILLING_ADDRESS into billingadd from PEOPLE where CUSTOMER_ID = userid;
    if billingadd is null then
        select ADRESS into billingadd from PEOPLE where  CUSTOMER_ID = userid;
    end if;
     return billingadd;


exception
   WHEN too_many_rows THEN
        dbms_output.put_line('Errors fetching are more than one');
        return 'Address not Found!';

    when others then
        dbms_output.put_line('Unknown error occured!');
                return 'Address not Found!';



END getAddress;
/

create synonym DECRYPTBYKEY for SYS.DECRYPTBYKEY
/

