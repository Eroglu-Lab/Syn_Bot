//Takes in a folder of images and gives the red and green channels Z-projected to be used for training ilastik

dir1  = getDirectory("Choose Source Directory ");
dir2  = getDirectory("Choose Red Directory ");
dir3  = getDirectory("Choose Green Directory ");
list  = getFileList(dir1);
setBatchMode(true);

for (i = 0; i < list.length; i++) {
	print(list[i]);
	open(dir1 + list[i]);
	title = getTitle();
	Stack.getDimensions(width, height, channels, slices, frames);
	print("slices: " + slices);
	if (slices > 1){
		run("RGB Color", "slices keep");
		title2 = getTitle();
		num = floor(slices / 3);
	for (j = 1; j <= num; j++) {
		end = j * 3;
		start = end - 2;
		run("Z Project...", "start=" + j + " stop=" + end + " projection=[Max Intensity]");
		run("Split Channels");
		selectWindow("MAX_" + title2 + " (red)");
		saveAs("Tiff", dir2 + title + " (red)_"+ j +".tif");
		close();
		selectWindow("MAX_" + title2 + " (green)");
		saveAs("Tiff", dir3 + title + " (green)_"+ j +".tif");
		close();
		close();
		}
	}
	if (slices == 1){
		run("Split Channels");
		selectWindow(title + " (red)");
		saveAs("Tiff", dir2 + title + " (red).tif");
		close();
		selectWindow(title + " (green)");
		saveAs("Tiff", dir3 + title + " (green).tif");
		close();
		close();
	}
	
	close("*");
}