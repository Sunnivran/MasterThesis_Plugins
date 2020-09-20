import os
import unittest
import vtk, qt, ctk, slicer
from slicer.ScriptedLoadableModule import *
import logging

import sys
import subprocess

#
# Segmentation_Caller
#

class Segmentation_Caller(ScriptedLoadableModule):
  """Uses ScriptedLoadableModule base class, available at:
  https://github.com/Slicer/Slicer/blob/master/Base/Python/slicer/ScriptedLoadableModule.py
  """

  def __init__(self, parent):
    ScriptedLoadableModule.__init__(self, parent)
    self.parent.title = "Segmentation Caller" # TODO make this more human readable by adding spaces
    self.parent.categories = ["Examples"]
    self.parent.dependencies = []
    self.parent.contributors = ["Piotr Zakowski"] # replace with "Firstname Lastname (Organization)"
    self.parent.helpText = """
This is an example of scripted loadable module bundled in an extension.
It performs a simple Python script call for segmentation
"""
    self.parent.helpText += self.getDefaultModuleDocumentationLink()
    self.parent.acknowledgementText = """
This file was originally developed by Jean-Christophe Fillion-Robin, Kitware Inc.
and Steve Pieper, Isomics, Inc. and was partially funded by NIH grant 3P41RR013218-12S1.
""" # replace with organization, grant and thanks.

#
# Segmentation_CallerWidget
#

class Segmentation_CallerWidget(ScriptedLoadableModuleWidget):
  """Uses ScriptedLoadableModuleWidget base class, available at:
  https://github.com/Slicer/Slicer/blob/master/Base/Python/slicer/ScriptedLoadableModule.py
  """

  def setup(self):
    ScriptedLoadableModuleWidget.setup(self)

    # Instantiate and connect widgets ...

    #
    # Parameters Area
    #
    parametersCollapsibleButton = ctk.ctkCollapsibleButton()
    parametersCollapsibleButton.text = "Parameters"
    self.layout.addWidget(parametersCollapsibleButton)

    # Layout within the dummy collapsible button
    parametersFormLayout = qt.QFormLayout(parametersCollapsibleButton)

    #
    # input volume selector
    #
    self.inputSelector = slicer.qMRMLNodeComboBox()
    self.inputSelector.nodeTypes = ["vtkMRMLScalarVolumeNode"]
    self.inputSelector.selectNodeUponCreation = True
    self.inputSelector.addEnabled = False
    self.inputSelector.removeEnabled = False
    self.inputSelector.noneEnabled = False
    self.inputSelector.showHidden = False
    self.inputSelector.showChildNodeTypes = False
    self.inputSelector.setMRMLScene( slicer.mrmlScene )
    self.inputSelector.setToolTip( "Pick the input image to the segmentation." )
    parametersFormLayout.addRow("Input Volume: ", self.inputSelector)
    
    self.inputPathLabel = qt.QLabel("")
    self.inputPathLabel.wordWrap = True
    parametersFormLayout.addRow("Input path: ", self.inputPathLabel)
    

    #
    # output path selector
    #
    # self.outputSelector = qt.QFileDialog()
    # self.outputSelector.setOption(qt.QFileDialog.ShowDirsOnly, True)
    # self.outputSelector.setToolTip("Choose destination folder for output segmentation")
    # parametersFormLayout.addRow(qt.QLabel("Output path:"))
    # parametersFormLayout.addRow(self.outputSelector)

    #
    # slider example
    #
    self.paramSliderWidget = ctk.ctkSliderWidget()
    self.paramSliderWidget.singleStep = 0.01
    self.paramSliderWidget.minimum = 0
    self.paramSliderWidget.maximum = 1
    self.paramSliderWidget.value = 0.5
    self.paramSliderWidget.setToolTip("Slider widget example for params")
    parametersFormLayout.addRow("Slider param: ", self.paramSliderWidget)

    #
    # textbox example
    #
    self.paramTextBoxWidget = qt.QLineEdit()
    self.paramTextBoxWidget.placeholderText = "Textbox param"
    self.paramTextBoxWidget.setToolTip("Text box widget example for params")
    parametersFormLayout.addRow("Text box param: ", self.paramTextBoxWidget)

    #
    # checkbox example
    #
    self.paramCheckBoxWidget = qt.QCheckBox()
    self.paramCheckBoxWidget.checked = 0
    self.paramCheckBoxWidget.setToolTip("Check box widget example for params")
    parametersFormLayout.addRow("Check box param: ", self.paramCheckBoxWidget)

    #
    # radiobutton example
    #
    self.paramGroupBoxWidget = qt.QGroupBox()
    self.radioButtonsOptions = []
    self.radioButtonsOptions.append(qt.QRadioButton("FirstOption"))
    self.radioButtonsOptions.append(qt.QRadioButton("SecondOption"))
    self.radioButtonsOptions.append(qt.QRadioButton("ThirdOption"))
    self.radioButtonsOptions[0].setChecked(True)
    self.paramChosedOption = self.radioButtonsOptions[0].text

    vbox = qt.QVBoxLayout()
    vbox.addWidget(qt.QLabel("Radio button param:"))
    for radioButton in self.radioButtonsOptions:
      vbox.addWidget(radioButton)

    self.paramGroupBoxWidget.setLayout(vbox)
    self.paramGroupBoxWidget.setToolTip("Group box with radio buttons widget example for params")  
    parametersFormLayout.addRow(self.paramGroupBoxWidget)    
    
    #
    # Apply Button
    #
    self.applyButton = qt.QPushButton("Apply")
    self.applyButton.toolTip = "Run the algorithm."
    self.applyButton.enabled = False
    parametersFormLayout.addRow(self.applyButton)

    # connections
    self.applyButton.connect('clicked(bool)', self.onApplyButton)
    self.inputSelector.connect("currentNodeChanged(vtkMRMLNode*)", self.onSelect)
    for radioButton in self.radioButtonsOptions:
      radioButton.connect("clicked(bool)", self.onClickedRadioButton)

    # Add vertical spacer
    self.layout.addStretch(1)

    # Refresh Apply button state
    self.onSelect()

  def cleanup(self):
    pass

  def pathFromNode(self, node):
    storageNode = node.GetStorageNode()
    if storageNode is not None: # loaded via drag-drop
      filepath = storageNode.GetFullNameFromFileName()
    else: # loaded via DICOM browser
      instanceUIDs = node.GetAttribute('DICOM.instanceUIDs').split()
      filepath = slicer.dicomDatabase.fileForInstance(instanceUIDs[0])
    return filepath

  def onSelect(self):
    self.applyButton.enabled = self.inputSelector.currentNode()
    if self.inputSelector.currentNode():
      self.inputPathLabel.text = self.pathFromNode(self.inputSelector.currentNode())
    else:
      self.inputPathLabel.text = ""

  def onClickedRadioButton(self):
    for option in self.radioButtonsOptions:
      if option.isChecked():
        self.paramChosedOption = option.text


  def onApplyButton(self):
    logic = Segmentation_CallerLogic()
    inputPath = self.inputPathLabel.text
    outputPath = qt.QFileDialog().getSaveFileName()
    params = '"'
    params += str(self.paramSliderWidget.value)
    params += '|' + str(self.paramTextBoxWidget.text)
    params += '|' + str(self.paramCheckBoxWidget.checked)
    params += '|' + str(self.paramChosedOption)
    params += '"'

    logging.info("Extension module:")
    logging.info(" input: "+inputPath)
    logging.info(" output: "+outputPath)
    logging.info(" params: "+params)

    logic.run(inputPath, outputPath, params)

#
# Segmentation_CallerLogic
#

class Segmentation_CallerLogic(ScriptedLoadableModuleLogic):
  """This class should implement all the actual
  computation done by your module.  The interface
  should be such that other python code can import
  this class and make use of the functionality without
  requiring an instance of the Widget.
  Uses ScriptedLoadableModuleLogic base class, available at:
  https://github.com/Slicer/Slicer/blob/master/Base/Python/slicer/ScriptedLoadableModule.py
  """

  def run(self, inputPath, outputPath, params):
    """
    Run the actual algorithm
    """

    if not inputPath:
      slicer.util.errorDisplay('Input path is empty. Save this volume or choose a different input.')
      return False

    logging.info('Processing started')

    #Logic
    scriptPath = os.path.dirname(os.path.abspath(__file__)) + '/SegmentationRedirect.sh'
    scriptOutput = subprocess.check_output([scriptPath, inputPath, outputPath, params])
    print(scriptOutput)

    logging.info('Processing completed')

    slicer.util.loadLabelVolume(outputPath)

    return True


class Segmentation_CallerTest(ScriptedLoadableModuleTest):
  """
  This is the test case for your scripted module.
  Uses ScriptedLoadableModuleTest base class, available at:
  https://github.com/Slicer/Slicer/blob/master/Base/Python/slicer/ScriptedLoadableModule.py
  """

  def setUp(self):
    """ Do whatever is needed to reset the state - typically a scene clear will be enough.
    """
    slicer.mrmlScene.Clear(0)

  def runTest(self):
    """Run as few or as many tests as needed here.
    """
    self.setUp()
    #self.test_Segmentation_Caller1()

  def test_Segmentation_Caller1(self):
    """ Ideally you should have several levels of tests.  At the lowest level
    tests should exercise the functionality of the logic with different inputs
    (both valid and invalid).  At higher levels your tests should emulate the
    way the user would interact with your code and confirm that it still works
    the way you intended.
    One of the most important features of the tests is that it should alert other
    developers when their changes will have an impact on the behavior of your
    module.  For example, if a developer removes a feature that you depend on,
    your test should break so they know that the feature is needed.
    """

    self.delayDisplay("Starting the test")
    #
    # first, get some data
    #
    self.delayDisplay('Finished with download and loading')
    logic = Segmentation_CallerLogic()
    self.assertIsNotNone( 1 )
    self.delayDisplay('Test passed!')
