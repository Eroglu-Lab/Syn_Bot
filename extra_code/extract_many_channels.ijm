//Takes in a folder of images and gives subfolders with each channel in the originals

setBatchMode(true);
dirSource  = getDirectory("Choose Source Directory ");
listSource = getFileList(dirSource);

firstImage = listSource[0];

run("Bio-Formats Importer", "open=["+dirSource+firstImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

Stack.getDimensions(width, height, channels, slices, frames);

for (i = 1; i < channels + 1; i++) {
	newDir = dirSource + File.separator + "channel_" + i;
	File.makeDirectory(newDir);
}

for (i = 0; i < listSource.length; i++) {
	currentImage = listSource[i];
	run("Bio-Formats Importer", "open=["+dirSource+currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	title = getTitle();
	splitArray = split(title, ".");
	splitName = splitArray[0];
	run("Split Channels");
	for (j = 1; j < channels + 1; j++) {
		selectWindow("C"+j+"-"+title);
		saveAs("tiff", dirSource + File.separator + "channel_" + j + File.separator + "C"+ j + "-" + title);
		close();
	}
}
