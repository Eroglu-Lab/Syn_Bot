dir1 = getDir("choose source directory");

list1 = getFileList(dir1);

dir2 = dir1 + File.separator + "cropped"

File.makeDirectory(dir2);

for (i = 0; i < list1.length; i++) {
	//setBatchMode(true);
	currentImage = list1[i];
	open(dir1 + File.separator + currentImage);
	setTool("freehand");
	//setBatchMode("exit and display");
	waitForUser("Draw freehand ROI around area to keep then click OK");
	roiManager("add");
	roiManager("save selected", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropping.roi");
	//setBatchMode("hide");
	getDimensions(width, height, channels, slices, frames);
	if (slices == 1){
	//this Duplicate only works for single stacks
	run("Duplicate...", " ");
	}
	if (slices > 1){
	//this Duplicate works for z-stacks stacks
	run("Duplicate...", "duplicate");
	}
	run("Clear Outside");
	saveAs("Tiff", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropped_inside.tif");
	close();
	run("Clear");
	saveAs("Tiff", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropped_outside.tif");
	close();

}