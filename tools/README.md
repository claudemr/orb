USING HIERO
===========

Generating distance field font atlas
------------------------------------

Laucnh hiero:

```
java -jar runnable-hiero.jar
```

Select "NEHE" button
Padding: 8 for each 4 sides. X = 0 Y = 0
Select "Glyph cache" radio button
Increase "Size" until before it fits on 2 pages
Select "Java" radio button for "Rendering"

In "Effect" tab, remove "Color" panel
In "Effect" tab, add "Distance field" panel
In distance field options, change "Spread" number up to 10
Improve the quality by increasing the "Scale" value (ie. 15)
Check it still fits on 1 page
"Save BMFont file (text)"...
