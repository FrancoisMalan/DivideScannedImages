# DivideScannedImages 

* is a plugin for [GIMP](http://en.wikipedia.org/wiki/GIMP).
* Is free (GPL)
* Is cross-platform, although one of its optional features (deskew) is only compiled for MS Windows
* Seems to work better than Adobe Photoshop for detecting and dividing scanned photographs! (in my personal experience)

## To make it run, you’ll have to
* [Download](http://www.gimp.org/downloads/) and install the latest version of **GIMP**
* (Optionally) [Download](http://francoismalan.com/wp-content/uploads/2013/01/deskew.exe) **deskew.exe** to GIMP’s plugin directory.
    * On my Windows computer this is C:\Program Files\GIMP 2\lib\gimp\2.0\plug-ins
* Download DivideScannedImages.scm (from this repository) and copy it to the GIMP scripts folder. 
    * On my computer this is C:\Program Files\GIMP 2\share\gimp\2.0\scripts
* Restart GIMP. You should now see the "Divide Scanned Images..." listed at the bottom of the "Filters" context menu (accessed from the menu bar). Click on it.
* For batch-processing a directory of scanned pages you can also access a batch-mode ”Batch Divide Scanned Images…” in the **Filters -> Batch Tools** sub-menu.

## Tips
* Unlike Adobe Photoshop, this plugin gives you some choice on how you want it to behave. 
    * Many of these settings should be self-explanatory. 
    * Important is that your scanned images have a consistent region that represents the “background color”. Typically this would be the corners of your scanned image. 
    * The background colour can best be determined automatically via the specified offset from one of the corners. However, a background colour may also be manually defined via supplied colour picker
    * If "deskew.exe" is not found to be present by the script, the "Run Deskew" option will have no effect

Feel free to experiment with the settings, especially:

* **Selection Threshold** which controls how sensitive the background color is defined in terms of separating it from the foreground photos.
* **Size Threshold** which controls the minimum size of any of the sub-images (rejects smaller items as noise)
* **Max number of items** which specifies the maximum number items to be extracted from a single page. 
* In batch mode the "load from" directory points to the folder of input scanned pages, and 
* the "target directory" to a (preferrably empty) directory that will contain the output.
* The "Save file base name" specifies the prefix that will be used for each output file, which is also sequentially numbered

Click on OK, and watch it run through your scanned image(s).

Comparing this solution to Photoshop's built-in filter surprised me, in that our filter seemed to be much more reliable, even straight out of the box. It is also possible to customise the filter’s behavior to suite your specific stack of scans.

Note, however, that DivideScannedImages can and will fail for difficult cases. Here are some more tips you should follow to maximize your chances of success:

* The photos should not overlap or touch each other. If they do, they will not be divided from each other by the automatic script
* The scanned page should be cropped in such a way that the to-be-identified items don't extend beyond the page background, and the page background should extend up to or beyond the image borders 
    * e.g. – seeing the wooden floor (on which an album was placed while photographing it) will confuse the algorithm unless you carefully set up the “Background Sample X/Y offset” values.
* The page background should be uniform (white or black are good), and have enough contrast relative to the photos
* The page (including the background) should be evenly lit

## On the web
* This script was originally posted [here](http://registry.gimp.org/node/22177)
* I've written a [blog post](http://francoismalan.com/2013/01/how-to-batch-separate-crop-multiple-scanned-photos/) explaining its usage