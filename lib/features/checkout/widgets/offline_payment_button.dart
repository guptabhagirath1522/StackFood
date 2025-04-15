import 'package:stackfood_multivendor/features/checkout/controllers/checkout_controller.dart';
import 'package:stackfood_multivendor/features/checkout/domain/models/offline_method_model.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class OfflinePaymentButton extends StatelessWidget {
  final bool isSelected;
  final List<OfflineMethodModel>? offlineMethodList;
  final bool isOfflinePaymentActive;
  final Function? onTap;
  final CheckoutController checkoutController;
  final JustTheController tooltipController;
  final bool? disablePayment;
  const OfflinePaymentButton({super.key, required this.isSelected, required this.offlineMethodList, required this.isOfflinePaymentActive, required this.onTap,
    required this.checkoutController, required this.tooltipController, this.disablePayment = false});

  @override
  Widget build(BuildContext context) {
    return (isOfflinePaymentActive && offlineMethodList != null && offlineMethodList!.isNotEmpty) ? InkWell(
      onTap: onTap as void Function()?,
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: Theme.of(context).disabledColor, width: 0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Column(children: [
          Row(children: [

            Expanded(
              child: Row(children: [

                Flexible(
                  child: Text(
                    'pay_offline'.tr,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: disablePayment! ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color),
                    overflow: TextOverflow.ellipsis, maxLines: 1,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                JustTheTooltip(
                  backgroundColor: Colors.black87,
                  controller: tooltipController,
                  preferredDirection: AxisDirection.up,
                  tailLength: 14,
                  tailBaseWidth: 20,
                  content: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('note'.tr, style: robotoMedium.copyWith(color: const Color(0xff90D0FF))),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          OfflinePaymentTooltipNoteWidget(
                            note: 'offline_payment_note_line_one'.tr,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          OfflinePaymentTooltipNoteWidget(
                            note: 'offline_payment_note_line_two'.tr,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          OfflinePaymentTooltipNoteWidget(
                            note: 'offline_payment_note_line_three'.tr,
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => tooltipController.showTooltip(),
                    child: isSelected ? Icon(Icons.info_rounded, color: Theme.of(context).primaryColor, size: 18) : const SizedBox(),
                  ),
                ),

              ]),
            ),

            // Expanded(child: SizedBox()),

            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 24,
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
            ),
            // const SizedBox(width: Dimensions.paddingSizeSmall),
          ]),
          SizedBox(height: isSelected ? Dimensions.paddingSizeLarge : 0),

          isSelected ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: Dimensions.paddingSizeDefault,
              mainAxisSpacing: Dimensions.paddingSizeDefault,
              mainAxisExtent: 50,
              crossAxisCount: ResponsiveHelper.isDesktop(context) ? 4 : 3,
            ),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: offlineMethodList!.length,
            itemBuilder: (context, index) {
              bool isSelected = checkoutController.selectedOfflineBankIndex == index;
              return InkWell(
                onTap: () => checkoutController.selectOfflineBank(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha: 0.8) : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  ),
                  child: Center(child: Text(offlineMethodList![index].methodName!,
                    style: robotoMedium.copyWith(color: isSelected ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyMedium!.color!),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ),
              );
            },
          ) : const SizedBox(),

        ]),
      ),
    ) : const SizedBox();
  }
}

class OfflinePaymentTooltipNoteWidget extends StatelessWidget {
  final String note;
  const OfflinePaymentTooltipNoteWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          flex: 0,
          child: Container(
            height: 5, width: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Text(note, style: robotoRegular.copyWith(color: Theme.of(context).cardColor))),
      ],
    );
  }
}
