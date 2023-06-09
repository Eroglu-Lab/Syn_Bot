//Asks user for source directory
dir1  = getDirectory("Choose Source Directory ");
list1  = getFileList(dir1);

dir2 = dir1 + "rotated_images"+File.separator;
	File.makeDirectory(dir2);

setBatchMode(true);

for (i = 0; i < list1.length; i++) {
	file = list1[i];
	print(list1[i]);
	if (endsWith(file, ".tif")){
		open(dir1 + file);
		Stack.getDimensions(width, height, channels, slices, frames);
		run("Select All");
		run("Split Channels");
		//close blue
		close(file + " (blue)");
		//Do the following for red and then green
		selectWindow(file + " (red)");
		title = getTitle();
		title = split(title, ".");
		run("Select All");
		run("Rotate 90 Degrees Right");
		selectWindow(file + " (green)");
		title = getTitle();
		title = split(title, ".");
		run("Merge Channels...", "c1=[" +file + 
		" (red)] c2=[" + file + " (green)] create");
		saveAs("Tiff", dir2 + title[0] + "_rotated");
		close("*");
	}
}