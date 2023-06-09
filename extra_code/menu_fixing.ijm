//Creates a dialog window for the user to input relevant parameters
Dialog.create("Syn Bot");
preprocessingList = newArray("Noise Reduction?", "Brightness Adjustment?");
channelList = newArray("2 Channel Colocalization (RG)", "3 Channel Colocalization (RGB)");
threshTypes = newArray("Manual", "Fixed Value", "Percent Histogram", "FIJI auto",
"ilastik", "Pre-Thresholded", "Threshold from File");
roiList = newArray("Whole Image", "Auto Cell Body", "Circle","Cell Territory" , "custom");
analysisList = newArray("Circle-based", "Pixel-based");
checkboxList = newArray("90 degree control?");

//Channels 
Dialog.setInsets(0, 10, 0);
Dialog.addMessage("Channels", 16);
Dialog.setInsets(0, 20, 0);
Dialog.addRadioButtonGroup("", channelList, 1, 2, "2 Channel Colocalization (RG)");
Dialog.setInsets(0, 20, 0);
Dialog.addCheckbox("Pick Channels?", false);

//Preprocessing
Dialog.setInsets(10, 10, 0);
Dialog.addMessage("Preprocessing", 16);
Dialog.setInsets(0, 20, 0);
Dialog.addCheckboxGroup(1, 2, preprocessingList, newArray(false,false));

//Thresholding
Dialog.setInsets(10, 10, 0);
Dialog.addMessage("Thresholding", 16);
Dialog.setInsets(0, 20, 0);
Dialog.addRadioButtonGroup("", threshTypes, 2, 3, "Manual");

//ROI Type
Dialog.setInsets(10, 10, 0);
Dialog.addMessage("ROI Type", 16);
Dialog.setInsets(0, 20, 0);
Dialog.addRadioButtonGroup("", roiList, 1, 5, "Whole Image");
Dialog.setInsets(0, 20, 0);
Dialog.addNumber("Red Min Pixel Size", 4);
Dialog.addToSameRow();
Dialog.addString("Red Max Pixel Size", "Infinity");
Dialog.setInsets(0, 20, 0);
Dialog.addNumber("Green Min Pixel Size", 4);
Dialog.addToSameRow();
Dialog.addString("Green Max Pixel Size", "Infinity");
Dialog.setInsets(0, 20, 0);
Dialog.addNumber("Blue Min Pixel Size", 4);
Dialog.addToSameRow();
Dialog.addString("Blue Max Pixel Size", "Infinity");

//Analysis Type
Dialog.setInsets(10, 10, 0);
Dialog.addMessage("Analysis Type?", 16);
Dialog.setInsets(0, 20, 0);
Dialog.addRadioButtonGroup("", analysisList, 1, 2, "Circle-based");
Dialog.setInsets(0, 20, 0);
Dialog.addCheckbox("90 degree control?", false);

//Experiment Directory
Dialog.setInsets(10, 10, 0);
Dialog.addMessage("Experiment Directory", 16);
Dialog.setInsets(0, 20, 0);
Dialog.addDirectory("", "");

Dialog.addHelp("https://github.com/Eroglu-Lab/Syn_Bot");
Dialog.show();

