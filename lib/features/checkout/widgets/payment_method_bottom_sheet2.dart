import 'package:stackfood_multivendor/common/widgets/custom_ink_well_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor/features/checkout/controllers/checkout_controller.dart';
import 'package:stackfood_multivendor/features/checkout/widgets/offline_payment_button.dart';
import 'package:stackfood_multivendor/features/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/business/controllers/business_controller.dart';
import 'package:stackfood_multivendor/helper/price_converter.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/styles.dart';
import 'package:stackfood_multivendor/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class PaymentMethodBottomSheet2 extends StatefulWidget {
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final bool isWalletActive;
  final double totalPrice;
  final bool isSubscriptionPackage;
  const PaymentMethodBottomSheet2({
    super.key, required this.isCashOnDeliveryActive, required this.isDigitalPaymentActive,
    required this.isWalletActive, required this.totalPrice, this.isSubscriptionPackage = false, required this.isOfflinePaymentActive});

  @override
  State<PaymentMethodBottomSheet2> createState() => _PaymentMethodBottomSheet2State();
}

class _PaymentMethodBottomSheet2State extends State<PaymentMethodBottomSheet2> {
  bool canSelectWallet = true;
  bool notHideCod = true;
  bool notHideWallet = true;
  bool notHideDigital = true;
  final JustTheController tooltipController = JustTheController();
  final TextEditingController _amountController = TextEditingController();
  bool showChangeAmount = false;

  @override
  void initState() {
    super.initState();

    if(Get.find<CheckoutController>().exchangeAmount > 0) {
      showChangeAmount = true;
      _amountController.text = Get.find<CheckoutController>().exchangeAmount.toString();
    }

    configurePartialPayment();

  }

  void configurePartialPayment() {
    if(!widget.isSubscriptionPackage && !Get.find<AuthController>().isGuestLoggedIn()){
      double walletBalance = Get.find<ProfileController>().userInfoModel!.walletBalance!;
      if(walletBalance < widget.totalPrice){
        canSelectWallet = false;
      }
      if(Get.find<CheckoutController>().isPartialPay){
        notHideWallet = false;
        if(Get.find<SplashController>().configModel!.partialPaymentMethod! == 'cod'){
          notHideCod = true;
          notHideDigital = false;
        } else if(Get.find<SplashController>().configModel!.partialPaymentMethod! == 'digital_payment'){
          notHideCod = false;
          notHideDigital = true;
        } else if(Get.find<SplashController>().configModel!.partialPaymentMethod! == 'both'){
          notHideCod = true;
          notHideDigital = true;
        }
      } else {
        notHideWallet = false;
        notHideCod = true;
        notHideDigital = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: 550,
      child: GetBuilder<CheckoutController>(builder: (checkoutController) {
          return GetBuilder<BusinessController>(builder: (businessController) {
            bool disablePayments = checkoutController.paymentMethodIndex == 1 && !checkoutController.isPartialPay;

            print('======check: ${widget.isDigitalPaymentActive} && $notHideDigital && ${!checkoutController.subscriptionOrder}');
              return Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.vertical(top: const Radius.circular(Dimensions.radiusLarge), bottom: Radius.circular(ResponsiveHelper.isDesktop(context) ? Dimensions.radiusLarge : 0)),
                ),
                //padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                child: Column(mainAxisSize: MainAxisSize.min, children: [

                  ResponsiveHelper.isDesktop(context) ? Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 30, width: 30,
                        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(50)),
                        child: const Icon(Icons.clear),
                      ),
                    ),
                  ) : Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 4, width: 35,
                      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(color: Theme.of(context).disabledColor, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text('choose_payment_method'.tr, style: robotoBold),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, top: 13),
                            child: Text('total_bill'.tr, style: robotoMedium.copyWith(fontSize: 14, color: Colors.grey.shade700)),
                          ),

                          Text(PriceConverter.convertPrice(widget.totalPrice), style: robotoMedium.copyWith(fontSize: 20, color: Theme.of(context).primaryColor)),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // Align(alignment: Alignment.center, child: Text('payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
                          // const SizedBox(height: Dimensions.paddingSizeLarge),
                          //
                          // !widget.isSubscriptionPackage && notHideCod ? Text('choose_payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)) : const SizedBox(),
                          // SizedBox(height: !widget.isSubscriptionPackage && notHideCod ? Dimensions.paddingSizeExtraSmall : 0),
                          //
                          // !widget.isSubscriptionPackage && notHideCod ? Text(
                          //   'click_one_of_the_option_below'.tr,
                          //   style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                          // ) : const SizedBox(),
                          // SizedBox(height: !widget.isSubscriptionPackage && notHideCod ? Dimensions.paddingSizeLarge : 0),

                          walletView(checkoutController),

                          !widget.isSubscriptionPackage && widget.isCashOnDeliveryActive && notHideCod ? paymentButtonView(
                            title: 'cash_on_delivery'.tr,
                            isSelected: checkoutController.paymentMethodIndex == 0,
                            disablePayments: disablePayments,
                            onTap: disablePayments ? null : (){
                              checkoutController.setPaymentMethod(0);
                            },
                          ) : const SizedBox(),

                          changeAmountView(checkoutController),

                          // !widget.isSubscriptionPackage ? Row(children: [
                          //   // widget.isCashOnDeliveryActive && notHideCod ? Expanded(
                          //   //   child: PaymentButtonNew(
                          //   //     icon: Images.codIcon,
                          //   //     title: 'cash_on_delivery'.tr,
                          //   //     isSelected: checkoutController.paymentMethodIndex == 0,
                          //   //     onTap: () {
                          //   //       checkoutController.setPaymentMethod(0);
                          //   //     },
                          //   //   ),
                          //   // ) : const SizedBox(),
                          //   // SizedBox(width: widget.isWalletActive && notHideWallet && !checkoutController.subscriptionOrder && isLoggedIn ? Dimensions.paddingSizeLarge : 0),
                          //
                          //   widget.isWalletActive && notHideWallet && !checkoutController.subscriptionOrder && isLoggedIn ? Expanded(
                          //     child: PaymentButtonNew(
                          //       icon: Images.partialWallet,
                          //       title: 'pay_via_wallet'.tr,
                          //       isSelected: checkoutController.paymentMethodIndex == 1,
                          //       onTap: () {
                          //         if(canSelectWallet) {
                          //           checkoutController.setPaymentMethod(1);
                          //         } else if(checkoutController.isPartialPay){
                          //           showCustomSnackBar('you_can_not_user_wallet_in_partial_payment'.tr);
                          //           Get.back();
                          //         } else{
                          //           showCustomSnackBar('your_wallet_have_not_sufficient_balance'.tr);
                          //           Get.back();
                          //         }
                          //       },
                          //     ),
                          //   ) : const SizedBox(),
                          //
                          // ]) : const SizedBox(),
                          // const SizedBox(height: Dimensions.paddingSizeSmall),

                          // widget.isDigitalPaymentActive && notHideDigital && !checkoutController.subscriptionOrder ? Row(children: [
                          //   Text('pay_via_online'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          //   Text(
                          //     'faster_and_secure_way_to_pay_bill'.tr,
                          //     style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                          //   ),
                          // ]) : const SizedBox(),
                          // SizedBox(height: widget.isDigitalPaymentActive && notHideDigital ? Dimensions.paddingSizeLarge : 0),

                          widget.isDigitalPaymentActive && notHideDigital && !checkoutController.subscriptionOrder ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              border: Border.all(color: Theme.of(context).disabledColor, width: 0.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  child: Text('pay_via_online'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: disablePayments ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color)),
                                ),

                                ListView.builder(
                                  itemCount: Get.find<SplashController>().configModel!.activePaymentMethodList!.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index){
                                    bool isSelected;
                                    if(widget.isSubscriptionPackage) {
                                      isSelected = businessController.paymentIndex == 1 && Get.find<SplashController>().configModel!.activePaymentMethodList![index].getWay! == businessController.digitalPaymentName;
                                    } else {
                                      isSelected = checkoutController.paymentMethodIndex == 2 && Get.find<SplashController>().configModel!.activePaymentMethodList![index].getWay! == checkoutController.digitalPaymentName;
                                    }
                                    return paymentButtonView(
                                      disablePayments: disablePayments,
                                      onTap: disablePayments ? null : (){
                                        if(widget.isSubscriptionPackage) {
                                          businessController.setPaymentIndex(1);
                                          businessController.changeDigitalPaymentName(Get.find<SplashController>().configModel!.activePaymentMethodList![index].getWay!);
                                        } else {
                                          checkoutController.setPaymentMethod(2);
                                          checkoutController.changeDigitalPaymentName(Get.find<SplashController>().configModel!.activePaymentMethodList![index].getWay!);
                                        }
                                      },
                                      title: Get.find<SplashController>().configModel!.activePaymentMethodList![index].getWayTitle!,
                                      isSelected: isSelected,
                                      image: Get.find<SplashController>().configModel!.activePaymentMethodList![index].getWayImageFullUrl,
                                    );
                                  }),
                              ],
                            ),
                          ) : const SizedBox(),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          widget.isOfflinePaymentActive && !checkoutController.subscriptionOrder ? OfflinePaymentButton(
                            isSelected: checkoutController.paymentMethodIndex == 3,
                            offlineMethodList: checkoutController.offlineMethodList,
                            isOfflinePaymentActive: widget.isOfflinePaymentActive,
                            onTap: disablePayments ? null : () => checkoutController.setPaymentMethod(3),
                            checkoutController: checkoutController, tooltipController: tooltipController,
                            disablePayment: disablePayments,
                          ) : const SizedBox(),

                        ],
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                      child: CustomButtonWidget(
                        buttonText: 'select'.tr,
                        onPressed: () => Get.back(),
                      ),
                    ),
                  ),
                ]),
              );
            }
          );
        }
      ),
    );
  }

  Widget paymentButtonView({required String title, String? image, required bool isSelected, required Function? onTap, bool disablePayments = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap as void Function()?,
        child: Container(
          decoration: image != null ? null : BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, width: 0.2),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(children: [

            image != null ? CustomImageWidget(
              height: 15, fit: BoxFit.contain,
              image: image, color: disablePayments ? Theme.of(context).disabledColor : null,
            ) : const SizedBox(),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Text(
                title,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: disablePayments ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color),
              ),
            ),

            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 24,
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
            ),

          ]),

        ),
      ),
    );
  }

  Widget changeAmountView(CheckoutController checkoutController) {
    return checkoutController.paymentMethodIndex == 0 ? Column(
      children: [
        showChangeAmount ? Container(
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          ),
          padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
          margin: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: Dimensions.paddingSizeExtraSmall, children: [

            Text('${'change_amount'.tr}(${Get.find<SplashController>().configModel?.currencySymbol})', style: robotoBold),

            Text('specify_the_amount_of_change_the_deliveryman_needs_to_bring_when_delivering_the_order'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            CustomTextFieldWidget(
              hintText: 'amount'.tr,
              showLabelText: false,
              inputType: TextInputType.number,
              isAmount: true,
              inputAction: TextInputAction.done,
              controller: _amountController,
              onChanged: (String value){
                checkoutController.setExchangeAmount(double.tryParse(value)??0);
              },
            ),
          ]),
        ) : const SizedBox(),

        CustomInkWellWidget(
          onTap: (){
            setState(() {
              showChangeAmount = !showChangeAmount;
            });
          },
          radius: Dimensions.radiusSmall,
          padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Text(showChangeAmount ? 'see_less'.tr : 'see_more'.tr , style: robotoBold.copyWith(color: Colors.blue)),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

      ],
    ) : const SizedBox();
  }

  Widget walletView(CheckoutController checkoutController) {
    double walletBalance = Get.find<ProfileController>().userInfoModel?.walletBalance??0;
    double balance = 0;
    if(walletBalance <= 0) {
      return const SizedBox();
    }
    if(walletBalance > widget.totalPrice && checkoutController.paymentMethodIndex == 1) {
      balance = walletBalance - widget.totalPrice;
    }
    bool isWalletSelected = checkoutController.paymentMethodIndex == 1 || checkoutController.isPartialPay;

    return Get.find<SplashController>().configModel!.partialPaymentStatus! && !checkoutController.subscriptionOrder
        && Get.find<SplashController>().configModel!.customerWalletStatus == 1
        && Get.find<ProfileController>().userInfoModel != null && (checkoutController.distance != -1)
        && Get.find<ProfileController>().userInfoModel!.walletBalance! > 0 ? Column(children: [
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor, width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Text(isWalletSelected ? 'wallet_remaining_balance'.tr : 'wallet_balance'.tr, style: robotoMedium.copyWith(fontSize: 12, color: Colors.grey.shade700)),

            Row(children: [
              Text(
                PriceConverter.convertPrice(isWalletSelected ? balance : walletBalance),
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              ),

              Text(
                isWalletSelected ? ' (${'applied'.tr})' : '',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
              ),
            ])
          ]),

          CustomInkWellWidget(
            onTap: () {
              if(isWalletSelected) {
                checkoutController.setPaymentMethod(-1);
                if(checkoutController.isPartialPay) {
                  checkoutController.changePartialPayment();
                }
              } else {
                if(checkoutController.isPartialPay) {
                  checkoutController.changePartialPayment();
                }
                checkoutController.setPaymentMethod(1);
                if(walletBalance < widget.totalPrice) {
                  checkoutController.changePartialPayment();
                }
              }
              configurePartialPayment();
            },
            radius: 5,
            child: isWalletSelected ? const Icon(Icons.clear, color: Colors.red) : Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: Theme.of(context).primaryColor, width: 1)),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
              child: Text('apply'.tr, style: robotoMedium.copyWith(fontSize: 12, color: Theme.of(context).primaryColor)),
            ),
          ),
        ]),
      ),

      if(isWalletSelected && !checkoutController.isPartialPay)
        Container(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

            Text('paid_by_wallet'.tr, style: robotoBold.copyWith(fontSize: 14)),
            Text(PriceConverter.convertPrice(widget.totalPrice), style: robotoMedium.copyWith(fontSize: 18))

          ]),
        ),


      if(isWalletSelected && checkoutController.isPartialPay)
        Column(children: [
          Container(
            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Column(children: [

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                Text('paid_by_wallet'.tr, style: robotoMedium.copyWith(fontSize: 14, color: Colors.grey.shade700)),
                Text(PriceConverter.convertPrice(walletBalance), style: robotoMedium.copyWith(fontSize: 14, color: Colors.grey.shade700))

              ]),
              const SizedBox(height: 5),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                Text('remaining_bill'.tr, style: robotoMedium.copyWith(fontSize: 14)),
                Text(PriceConverter.convertPrice(widget.totalPrice - walletBalance), style: robotoBold.copyWith(fontSize: 18)),

              ])
            ]),
          ),

          if(checkoutController.paymentMethodIndex == 1)
            Text('* ${'please_select_a_option_to_pay_remain_billing_amount'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFFE74B4B))),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ]),


    ]) : const SizedBox();
  }

  void _checkFormatters(String value) {
    String test = '';
    if(value.contains('-')) {
      test = value.replaceAll('-', '');
    } else if(value.contains(' ')) {
      test = value.replaceAll(' ', '');
    } else if(value.contains(',')) {
      test = value.replaceAll(',', '');
    } else {
      test = value;
    }
    setState(() {
      _amountController.text = test;
    });
  }
}

