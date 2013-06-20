# DevideScannedImages 

* is a plugin for [GIMP](http://en.wikipedia.org/wiki/GIMP).
* Is free (GPL)
* Works better than Adobe Photoshop for detecting and dividing scanned photographs! (in my personal experience)

## To make it run, you’ll have to
* [Download](http://www.gimp.org/downloads/) and install the latest version of **GIMP**
* [Download](http://francoismalan.com/wp-content/uploads/2013/01/deskew.exe) **deskew.exe** to GIMP’s plugin directory.
    * On my Windows computer this is C:\Program Files\GIMP 2\lib\gimp\2.0\plug-ins
* Download DivideScannedImages (this repository) and copy **DivideScannedImages.scm** to the GIMP scripts folder. 
    * On my computer this is C:\Program Files\GIMP 2\share\gimp\2.0\scripts
* Restart GIMP. You should now see the ”Batch Divide Scanned Images…” option as a sub-menu under **Filters -> Batch Tools**. Click on it.

## Tips
* Unlike Adobe Photoshop, this plugin gives you some choice on how you want it to behave. 
    * Many of these settings should be self-explanatory. 
    * Important is that your scanned images have a consistent region that represents the “background color”. Typically this would be the corners of your scanned image. 

For me, the following settings worked well:
        * Selection Threshold = 25
		* Size Threshold = 100
		* Abort Limit = 10
		* Background Sample X Offset = 5.0
		* Background Sample Y Offset = 5.0

Feel free to experiment with the settings, especially:

* **Selection Threshold** which controls how sensitive the background color is defined in terms of separating it from the foreground photos.
* **Abort Limit** which specifies the maximum number of photos can be detected on a single page. 
* The “load from” directory should point to the folder of input scanned pages, and 
* the “save directory” to an empty directory that will contain the output.

Click on OK, and watch it run through all your photos.

Comparing this solution to Photoshop's built-in filter surprised me, in that our filter seemed to be much more reliable, even straight out of the box. It is also possible to customise the filter’s behavior to suite your specific stack of scans.

Note, however, that DivideScannedImages can and will fail for difficult cases. Here are some more tips you should follow to maximize your chances of success:

* The photos should not overlap or touch each other. If they do, they will not be divided from each other by the automatic script
* The scan / photograph borders should be cropped in such a way that it doesn’t extent beyond the page background, and the page background should extend up to or beyond the image borders 
	* e.g. – seeing the wooden floor (on which an album was placed while photographing it) will screw up the algorithm unless you carefully set up the “Background Sample X/Y offset” values.
* The page background should be uniform (white or black are good), and have enough contrast relative to the photos
* The page (including the background) should be evenly lit

## On the web
* This script was originally posted [here](http://registry.gimp.org/node/22177)
* I've written a [blog post](http://francoismalan.com/2013/01/how-to-batch-separate-crop-multiple-scanned-photos/) explaining its usage