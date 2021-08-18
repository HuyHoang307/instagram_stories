import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_stories/data.dart';
import 'package:instagram_stories/models/story_model.dart';
import 'package:instagram_stories/models/user_model.dart';
import 'package:video_player/video_player.dart';

class StoryScreen extends StatefulWidget {
  final List<Story> stories;
  final VoidCallback increment;
  final VoidCallback decrement;

  StoryScreen(
      {Key? key,
      required this.stories,
      required this.decrement,
      required this.increment})
      : super(key: key);

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with SingleTickerProviderStateMixin{
  late PageController _pageController;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;


  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(vsync: this);

    final Story firstStory = widget.stories.first;
    _loadStory(story: firstStory, animateToPage: false);

    _animationController.addStatusListener((status) {
      if(status == AnimationStatus.completed) {
        _animationController.stop();
        _animationController.reset();
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex += 1;
          }else{
            widget.increment();
          }
          _loadStory(story: widget.stories[_currentIndex]);
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final Story story = widget.stories[_currentIndex];
    return Scaffold(
       backgroundColor: Colors.black,
       body: GestureDetector(
         onTapDown: (detail) => _onTapDown(detail, story),
         child: Stack(
           children: [
             PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.stories.length,
                  itemBuilder: (context, i) {
                    final Story story = widget.stories[i];
                    switch (story.media) {
                      case MediaType.image:
                        return CachedNetworkImage(
                            imageUrl: story.url, fit: BoxFit.cover);
                      case MediaType.video:
                        if (_videoController != null &&
                            _videoController!.value.isInitialized) {
                          return FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          );
                        }
                        break;
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Positioned(
                    top: 40.0,
                    left: 10.0,
                    right: 10.0,
                    child: Column(
                      children: [
                        Row(
                          children: widget.stories
                              .asMap()
                              .map((key, value) => MapEntry(
                                  key,
                                  AnimateBar(
                                      animationController: _animationController,
                                      position: key,
                                      currentIndex: _currentIndex)))
                              .values
                              .toList(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 1.5, vertical: 10.0),
                          child: UserInfo(
                            user: story.user,
                          ),
                        )
                      ],
                    ))
           ],
         )
       )
    );
  }

  void _onTapDown(TapDownDetails details, Story story) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth/3){
      setState(() {
        if (_currentIndex -1 >= 0){
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]); 
        }else {
          widget.decrement();
        }
      });
    }else if (dx > 2 * screenWidth / 3){
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
        }else{
          widget.increment();
        }
      });
    }else{
      if (story.media == MediaType.video) {
        if(_videoController!.value.isPlaying) {
          _videoController!.pause();
          _animationController.stop();
        }else{
          _videoController!.play();
          _animationController.forward();
        }
      }
    }
  }

  void _loadStory({required Story story, bool animateToPage = true}) {
    _animationController.stop();
    _animationController.reset();
    switch (story.media) {
      case MediaType.image:
        _animationController.duration = story.duration;
        _animationController.forward();
        break;
      case MediaType.video:
        _videoController = null;
        _videoController?.dispose();
        _videoController = VideoPlayerController.network(story.url)
          ..initialize().then((_) {
            setState(() {
              if (_videoController!.value.isInitialized) {
                _animationController.duration = _videoController!.value.duration;
                _videoController!.play();
                _animationController.forward();
              }
            });
          });
        break;
    }
    if (animateToPage) {
      _pageController.animateToPage( _currentIndex, duration: const Duration(microseconds: 1), curve: Curves.easeInOut);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'Flutter Instagram Stories',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ListStoryDetail(listStory: [
          stories,
          stories,
          stories,
          stories,
        ], currentIndex: 0)
    );
  }
}

class AnimateBar extends StatelessWidget{
  final AnimationController animationController;
  final int position;
  final int currentIndex;

  const AnimateBar({
    Key? key,
    required this.animationController,
    required this.position,
    required this.currentIndex
  }):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _builderContainer(
                  double.infinity,
                  position < currentIndex ? Colors.white : Colors.white.withOpacity(0.5)
                ),
                position == currentIndex
                ? AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return _builderContainer(
                      constraints.maxWidth * animationController.value,
                      Colors.white
                    );
                  }
                )
                : const SizedBox.shrink()
              ],
            );
          },
        ),
      ),
    );
  }

  Container _builderContainer(double width, Color color) {
    return Container(
      height: 5.0,
      width: width,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black26,
          width: 0.8
        ),
        borderRadius: BorderRadius.circular(3.0),
      ),
    );
  }
}

class UserInfo extends StatelessWidget {
  final User user;

  const UserInfo({
    Key? key,
    required this.user
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 20.0,
          backgroundColor: Colors.grey[300],
          backgroundImage: CachedNetworkImageProvider(user.profileImageUrl)
        ),
        const SizedBox(width: 10.0,),
        Expanded(
          child: Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w600
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.close,
            size: 30.0,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }
}

class ListStoryDetail extends StatefulWidget {
  final List<List<Story>> listStory;
  final int currentIndex;
  ListStoryDetail({Key? key, required this.listStory, required this.currentIndex}) : super(key: key);

  @override
  _ListStoryDetailState createState() => _ListStoryDetailState();
}

class _ListStoryDetailState extends State<ListStoryDetail> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: widget.listStory.length,
      itemBuilder: (context, i) {
        return StoryScreen(stories: widget.listStory[i], increment: () {increment(context);}, decrement: () { decrement(context); },);
      },
    );
  }

  void increment(BuildContext context) {
    setState(() {
      if (_currentIndex + 1 < widget.listStory.length) {
        _currentIndex += 1;
        _pageController.animateToPage(_currentIndex, duration: const Duration(microseconds: 300), curve: Curves.easeInOut);
      }else {
        Navigator.of(context).pop();
      }
    });
  }
  void decrement(BuildContext context) {
    setState(() {
      if (_currentIndex - 1 >= 0) {
        _currentIndex -= 1;
        _pageController.animateToPage(_currentIndex,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut);
      } else {
        Navigator.of(context).pop();
      }
    });
  }

}
void main() => runApp(MyApp());