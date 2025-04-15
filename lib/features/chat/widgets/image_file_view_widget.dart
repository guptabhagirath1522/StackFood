
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackfood_multivendor/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor/features/chat/controllers/chat_controller.dart';
import 'package:stackfood_multivendor/features/chat/domain/models/message_model.dart';
import 'package:stackfood_multivendor/features/chat/screens/preview_screen.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/images.dart';
import 'package:stackfood_multivendor/util/styles.dart';

class ImageFileViewWidget extends StatefulWidget {
  final Message currentMessage;
  final bool isRightMessage;
  const ImageFileViewWidget({super.key, required this.currentMessage, required this.isRightMessage});

  @override
  State<ImageFileViewWidget> createState() => _ImageFileViewWidgetState();
}

class _ImageFileViewWidgetState extends State<ImageFileViewWidget> {
  bool showAllImages = false;
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
      maxHeight: 100, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
      quality: 75,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: !showAllImages ? (widget.currentMessage.filesFullUrl!.length > 3 ? 4 : widget.currentMessage.filesFullUrl!.length)
          : widget.currentMessage.filesFullUrl!.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
      ),
      itemBuilder: (context, index) {

        String url = widget.currentMessage.filesFullUrl![index];

        return InkWell(
          onTap: () {
            if(isDesktop) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                    insetPadding: EdgeInsets.symmetric(horizontal: context.width * 0.3, vertical: context.height * 0.2),
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    child: PreviewScreen(images: widget.currentMessage.filesFullUrl!, selectedIndex: index),
                  );
                },
              );
            } else {
              Get.to(() => PreviewScreen(images: widget.currentMessage.filesFullUrl!, selectedIndex: index));
            }
          },
          onLongPress: () => Get.find<ChatController>().toggleOnClickImageAndFile(widget.currentMessage.id!),
          child: Stack(
            children: [
              Hero(
                tag: url,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: Get.find<ChatController>().isVideoExtension(url)
                      ? thumbnailView(index)
                      : CustomImageWidget(image: url, fit: BoxFit.cover, height: double.infinity, width: double.infinity,),
                ),
              ),

              if(Get.find<ChatController>().isVideoExtension(url) && !GetPlatform.isWeb)
                Center(child: Icon(Icons.play_circle, color: Colors.white,)),

              if(!showAllImages && (widget.isRightMessage ? (isDesktop ? index == 0 : index == 2 ) : (isDesktop ? index == 3 : index == 3))
                  && widget.currentMessage.filesFullUrl!.length > 3 && widget.currentMessage.filesFullUrl!.length != 4)
                InkWell(
                  onTap: (){
                    setState(() {
                      showAllImages = true;
                    });
                  },
                  child: Container(
                    height: double.infinity, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.currentMessage.filesFullUrl!.length -4} +',
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Theme.of(context).cardColor),
                    ),
                  ),
                )
            ],
          ),
        );

      },
    );
  }

  Widget thumbnailView(int index) {
    return  kIsWeb
        ? Image.asset(Images.videoPlaceholder, fit: BoxFit.cover, height: double.infinity, width: double.infinity)
        : thumbnailList.isNotEmpty && thumbnailList[index] != null ? Image.file(
      File(thumbnailList[index]!.path),
      fit: BoxFit.cover, height: double.infinity, width: double.infinity,
    ) : const SizedBox();
  }


}
