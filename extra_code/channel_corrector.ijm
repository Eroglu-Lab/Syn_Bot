//Get the source directory
dir1 = getDirectory("choose source directory");
list1 = getFileList(dir1);

dir2 = dir1 + File.separator + "channel_corrected"

File.makeDirectory(dir2);

Dialog.create("Channel Correction");
Dialog.addNumber("red channel", 0);
Dialog.addNumber("green channel", 0);
Dialog.addNumber("blue channel", 0);
Dialog.show();

red_number = Dialog.getNumber();
green_number = Dialog.getNumber();
blue_number = Dialog.getNumber();

red_string = d2s(red_number, 0);
green_string = d2s(green_number, 0);
blue_string = d2s(blue_number, 0);

setBatchMode(true);

for (i = 0; i < list1.length; i++) {

	//open the image
	run("Bio-Formats Importer", "open=["+dir1+list1[i]+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	//get the title
	title = getTitle();
	splitName = split(title, ".");
	
	//split the channels
	run("Split Channels");
	//merge channels, assuming that red_string is red (synaptic marker), green_string is green (other synaptic marker), blue_string is blue (cell territory)
	run("Merge Channels...", "c1=[C"+red_string+"-"+title+"] c2=[C"+green_string+"-"+title+"] c3=[C"+blue_string+"-"+title+"] create ignore");
	
	saveAs("tiff", dir2 + File.separator + splitName[0]);
	
	close("*");
}
