
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackfood_multivendor/common/widgets/custom_ink_well_widget.dart';
import 'package:stackfood_multivendor/features/chat/controllers/chat_controller.dart';
import 'package:stackfood_multivendor/features/chat/domain/models/message_model.dart';
import 'package:stackfood_multivendor/features/chat/screens/preview_screen.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/images.dart';
import 'package:stackfood_multivendor/util/styles.dart';

class PdfViewWidget extends StatefulWidget {
  final Message currentMessage;
  final bool isRightMessage;
  const PdfViewWidget({super.key, required this.currentMessage, required this.isRightMessage});

  @override
  State<PdfViewWidget> createState() => _PdfViewWidgetState();
}

class _PdfViewWidgetState extends State<PdfViewWidget> {
  List<XFile?> thumbnailList = [];

  @override
  void initState() {
    super.initState();

    generateThumbnailList();
  }

  Future<void> generateThumbnailList() async {
    if(widget.currentMessage.filesFullUrl != null && widget.currentMessage.filesFullUrl!.isNotEmpty) {
      for (var url in widget.currentMessage.filesFullUrl!) {
        if(Get.find<ChatController>().isVideoExtension(url)) {
          thumbnailList.add(await _thumbnail(url));
        } else {
          thumbnailList.add(null);
        }
      }
      setState(() {});
    }
  }

  Future<XFile> _thumbnail(String url) async {
    return await VideoThumbnail.thumbnailFile(
      video: url,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.WEBP,
      maxHeight: 100,
      quality: 75,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.currentMessage.filesFullUrl!.length,
        itemBuilder: (context, index){
          String url = widget.currentMessage.filesFullUrl![index];

          if(Get.find<ChatController>().isVideoExtension(url) && thumbnailList.isNotEmpty) {
            return CustomInkWellWidget(
              onTap: ()=> Get.to(PreviewScreen(images: [url], selectedIndex: index)),
              padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Stack(children: [
                thumbnailView(index),

                if(!GetPlatform.isWeb)
                  Positioned.fill(child: Center(child: Icon(Icons.play_circle, color: Colors.white))),

              ]),
            );
          }

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor, width: 0.3),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: InkWell(
          onTap: (){
            Get.find<ChatController>().downloadPdf(url);
          },
          child: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(crossAxisAlignment: CrossAxisAlignment.center,children: [
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Image.asset(Images.fileIcon,height: 30, width: 30),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Expanded(child: Text(
                  '${'attachment'.tr} ${index + 1}.pdf',
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                )),


              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget thumbnailView(int index) {
    return  kIsWeb
        ? ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Image.asset(Images.videoPlaceholder, fit: BoxFit.cover, height: 100, width: double.infinity),
    )
        : thumbnailList.isNotEmpty && thumbnailList.length > index && thumbnailList[index] != null ? ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Image.file(File(thumbnailList[index]!.path)),
    ) : const SizedBox();
  }
}
