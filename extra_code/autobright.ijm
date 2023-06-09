//Asks user for source directory
dir1  = getDirectory("Choose Source Directory ");
list1  = getFileList(dir1);

dir2 = dir1 + "autobright"+File.separator;
	File.makeDirectory(dir2);

Dialog.create("Brightness Adjustment");
Dialog.addNumber("Enter Percent Red Saturated Pixels", 0.35);
Dialog.addNumber("Enter Percent Green Saturated Pixels", 0.35);
Dialog.show();
brightPercentRed = Dialog.getNumber();
brightPercentGreen = Dialog.getNumber();

setBatchMode(true);

for (i = 0; i < list1.length; i++) {
	file = list1[i];
	print(list1[i]);
	if (endsWith(file, ".czi")){
		run("Bio-Formats Importer", "open=["+dir1+file+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		title = getTitle();
		splitName = split(title, ".");
		Stack.getDimensions(width, height, channels, slices, frames);
		run("Select All");
		run("RGB Color", "slices");
		run("Split Channels");
		close(title + " (blue)");
		selectWindow(title + " (red)");
		run("Enhance Contrast", "saturated="+brightPercentRed);
		run("Apply LUT", "stack");
		selectWindow(title + " (green)");
		run("Enhance Contrast", "saturated="+brightPercentGreen);
		run("Apply LUT", "stack");
		run("Merge Channels...", "c1=["+title+" (red)] c2=["+title+" (green)] create");
		saveAs("Tiff", dir2 + splitName[0] + "_autobright");
		close("*");
	}
}

print("Done");