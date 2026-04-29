import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

class StarRating extends StatefulWidget {
  final int starCount;
  final int currentRating;
  final double starSize;
  final Color color;
  final Function(int)? onRatingChanged;

   const StarRating({
    super.key,
    this.starCount = 5,
    this.starSize = 30.0,
    this.color = TColors.primary,
    this.onRatingChanged,
   this.currentRating = 0,
  });

  @override
  StarRatingState createState() => StarRatingState();
}

class StarRatingState extends State<StarRating> {

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        return IconButton(
          onPressed: () {
            int count = index;
            count++;
           widget.onRatingChanged!(count);
          },
          icon: Icon(
            index < widget.currentRating ? Icons.star : Icons.star_border,
            color: widget.color,
            size: widget.starSize,
          ),
        );
      }),
    );
  }
}
