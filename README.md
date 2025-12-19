# Sketch-Recognition-ML-Prototype
# Overview
This project explores end-to-end machine learning model development and on-device inference for hand-drawn sketch recognition.
I trained a machine learning model to classify simple object sketch using a publicly available sketch dataset from Google, and built a basic iPad application to capture user drawings and run predicitions locally. 

The goal of this project was to understand the full ML pipeline from data and training to deployment and mobile integration.
# Dataset
- Used a public sketch dataset released by Google containing hand-drawn sketches of common objects
- Dataset includes sketches drawn by many users, providing diverse drawing styles
- Data was preprocessed and used for supervised model training

# Model Training
- Trained the model using Google Colab
- Focused on achieving strong classification accuracy on sketch inputs
- Exported the trained model for use outside the training environment
- Converted the trained model into a format compatible with Core ML for on-device inference

# iPad Application
- Built a simple iPad app using Swift and UIKit
- Features:
    - Canvas for drawing sketches
    - Submit button to trigger predicition
    - Clear button to reset the canvas
- Used PencilKit to capture user drawings
- Integrated the trained model using Core ML to run inference directly on the device

# Tech Stack
- Python (model training)
- Google Colab
- Machine Learning
- Swift
- UIKit
- PencilKit
- Core ML
