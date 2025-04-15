import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:stackfood_multivendor/common/widgets/custom_ink_well_widget.dart';
import 'package:stackfood_multivendor/features/chat/controllers/chat_controller.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/styles.dart';
import 'package:video_player/video_player.dart';

class PreviewScreen extends StatefulWidget {
  final List<String> images;
  final int selectedIndex;
  const PreviewScreen({super.key, required this.images, required this.selectedIndex});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late VideoPlayerController? videoPlayerController;
  ChewieController? _chewController;

  @override
  void initState() {
    super.initState();

    _currentPage = widget.selectedIndex;
    _pageController =  PageController(initialPage: widget.selectedIndex);

    Future.delayed(const Duration(milliseconds: 200), () {
      _loadVideo();
    });
  }

  Future<void> _loadVideo() async {
    if(Get.find<ChatController>().isVideoExtension(widget.images[_currentPage])) {
      print('=====here====');
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.images[_currentPage]));
    }

    print('=======video : ${videoPlayerController}');
    if(videoPlayerController != null){
      _chewController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        allowFullScreen: false,
        placeholder: const Center(child: CircularProgressIndicator()),
      );
      await _chewController?.play();


      bool isNotExecute = true;

      _chewController?.videoPlayerController.addListener(() {
        if((videoPlayerController?.value.isInitialized ?? false) && isNotExecute){
          isNotExecute = false;
          setState(() {
            _chewController = ChewieController(
              videoPlayerController: videoPlayerController!,
              autoPlay: true,
              allowFullScreen: false,
              aspectRatio: videoPlayerController?.value.aspectRatio,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error) =>  Center(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Theme.of(context).hintColor, size: 40),

                    Text('this_video_is_not_supported_please_download_and_pay'.tr, style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeExtraSmall,
                    )),
                  ],
                ),
              )),
            );


          });
        }
      });

    }
  }

  @override
  void dispose() {
    _chewController?.pause();
    _chewController?.dispose();
    videoPlayerController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: isDesktop ? Colors.transparent : Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (i) async {
                setState(() {
                  _currentPage = i;
                });
                await _loadVideo();
              },
              itemCount: widget.images.length,
                itemBuilder: (context, index) {
              return Get.find<ChatController>().isVideoExtension(widget.images[_currentPage]) && _chewController != null && _chewController!.videoPlayerController.value.isInitialized ? Flexible(
                child: Center(child: Chewie(controller: _chewController!)),
              ) : PhotoView(
                backgroundDecoration: BoxDecoration(color: isDesktop ? Colors.transparent : Colors.black),
                tightMode: true,
                imageProvider: NetworkImage(widget.images[index]),
                heroAttributes: PhotoViewHeroAttributes(tag: widget.images[index]),
              );
            }),

            Positioned(top: 10, right: 0, child: IconButton(
              splashRadius: 5,
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.clear, color: Colors.white),
            )),

            if(_currentPage > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDesktop ? Colors.white : Colors.black),
                  ),
                  margin: EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                  child: CustomInkWellWidget(
                    onTap: _previousPage,
                    radius: 50,
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Icon(Icons.arrow_back, color: isDesktop ? Colors.white : Colors.black),
                  ),
                ),
              ),

            if (_currentPage < widget.images.length - 1)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDesktop ? Colors.white : Colors.black),
                  ),
                  margin: EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  child: CustomInkWellWidget(
                    onTap: _nextPage,
                    radius: 50,
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Icon(Icons.arrow_forward, color: isDesktop ? Colors.white : Colors.black),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < widget.images.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
}
