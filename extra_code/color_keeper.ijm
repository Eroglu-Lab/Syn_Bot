dir1  = getDirectory("Choose Source Directory ");
dir2  = getDirectory("Choose Destination Directory ");
list  = getFileList(dir1);
setBatchMode(true);

Dialog.create("Color Keeper");
Dialog.addMessage("Select which colors to keep");
Dialog.addCheckbox("Red", true);
Dialog.addCheckbox("Green", false);
Dialog.addCheckbox("Blue", true);
Dialog.show();
redBool = Dialog.getCheckbox();
greenBool = Dialog.getCheckbox();
blueBool = Dialog.getCheckbox();

finalC1 = "";
finalC2 = "";
finalC3 = "";
colorToDiscard = "";
colorToChange = "";
colorToKeep = "";
if(redBool&&greenBool){
	colorToChange = "";
	colorToDiscard = "Blue";
	colorToKeep = "Red+Green";
	finalC1 = "red";
	finalC2 = "green";
	finalC3 = "blue";
	
}
if(redBool&&blueBool){
	colorToChange = "blue";
	colorToDiscard = "Green";
	colorToKeep = "Red";
	finalC1 = "red";
	finalC2 = "blue";
	finalC3 = "green";
}
if(greenBool&&blueBool){
	colorToChange = "blue";
	colorToDiscard = "Red";
	colorToKeep = "Green";
	finalC1 = "blue";
	finalC2 = "green";
	finalC3 = "red";
	
}
if(redBool&&greenBool&&blueBool){
	colorToChange = "";
	colorToDiscard = "";
	colorToKeep = "all";
	colorCode = "RGB";
	finalC1 = "red";
	finalC2 = "green";
	finalC3 = "blue";
}

for (i = 0; i < list.length; i++) {
	print(list[i]);
	//open(dir1 + list[i]);
	run("Bio-Formats Importer", "open=["+dir1+list[i]+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");		
	title = getTitle();
	run("RGB Color", "slices");
	run("Split Channels");
	selectWindow(title + " (" + colorToDiscard.toLowerCase + ")");
	run("Select All");
	setBackgroundColor(0, 0, 0);
	run("Clear", "stack");
	
	selectWindow(title+" ("+ colorToChange +")");
	run(colorToDiscard);
	selectWindow(title + " (" + colorToKeep.toLowerCase + ")");
	run(colorToKeep);
	
	run("Merge Channels...", "c1=["+title+" ("+finalC1+")] c2=["+title+" ("+finalC2+")] c3=["+title+" ("+finalC3+")] create");
	
	
	saveAs("Tiff", dir2 + title + ".tif");
	close("*");
}
print("Done");
