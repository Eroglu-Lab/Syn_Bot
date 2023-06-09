if(indexOf(getInfo("os.name"), "Windows") >= 0){
		print("Windows Detected");
		ilastikDir = File.openDialog("Choose ilastik location");
	}
	else if(indexOf(getInfo("os.name"), "Mac") >= 0){
		print("Mac Detected");
		ilastikDir = getDirectory("Choose ilastik location");
	}
	else{
		print("Unknown OS");
		ilastikDir = getDirectory("Choose ilastik location");
	}
ilpDir = File.openDialog("Choose ilp file");
title = getTitle();
setBatchMode("hide");
run("Configure ilastik for Syn_Bot", "executablefile=["+ilastikDir+"] numthreads=-1 maxrammb=4096");

run("Run Pixel Classification Prediction for Syn_Bot", "projectfilename=["+ilpDir+"] saveonly=false inputimage=["+title+"] pixelclassificationtype=Probabilities");

//run edited pixel classification that doesn't delete temp
//import temp from h5 



h5Path_in = getDirectory("imagej")+ File.separator + "ilastik4ij_in_raw.h5";
h5Path_out = getDirectory("imagej")+ File.separator + "ilastik4ij_out.h5";
print(h5Path_out);

run("Import HDF5 for Syn_Bot", "select="+h5Path_out+" datasetname=/exported_data axisorder=tzyxc");

imgList = getList("image.titles");
for (i = 0; i < imgList.length; i++) {
	print("Image " + i + "is: " + imgList[i]);
}

//selects the second image (the output from ilastik)
selectImage(2);

saveAs("Tiff", getDirectory("downloads") + File.separator + "ilastik_out.tiff");

File.delete(h5Path_in);
File.delete(h5Path_out);

setBatchMode("exit and display");

run("8-bit");

run("Auto Threshold", "method=Default white");

//setBatchMode(false);