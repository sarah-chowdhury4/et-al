# Literature

Foundation papers for: label smoothing on small networks trained with noisy labels.
All records and links from OpenAlex.

## 1. Label smoothing

1. **Rethinking the Inception Architecture for Computer Vision** — Christian Szegedy, 2016 · 32971 citations · https://openalex.org/W2183341477  
   Introduces label smoothing as a soft-target regularizer in deep classifiers; the origin of the technique this project tests.

2. **When Does Label Smoothing Help?** — Rafael Rios Müller, 2019 · 1168 citations · https://openalex.org/W2970206392  
   Explains how soft targets change representations and calibration; frames when LS should help or hurt.

3. **Does label smoothing mitigate label noise?** — Michał Łukasik, 2020 · 204 citations · https://openalex.org/W3009419078  
   Directly studies LS under label noise; closest prior to our research question.

## 2. Learning with noisy labels

4. **Generalized Cross Entropy Loss for Training Deep Neural Networks with Noisy Labels** — Zhilu Zhang, 2018 · 2002 citations · https://openalex.org/W2803187616  
   Core noisy-label loss that sits between MAE and CE; baseline family for noise-robust training.

5. **Co-teaching: Robust Training of Deep Neural Networks with Extremely Noisy Labels** — Bo Han, 2018 · 1703 citations · https://openalex.org/W2963735582  
   Shows deep nets memorize noise and proposes peer-network sample selection; defines the noisy-label problem setting.

6. **Making Deep Neural Networks Robust to Label Noise: A Loss Correction Approach** — Giorgio Patrini, 2017 · 1527 citations · https://openalex.org/W2964292098  
   Foundational loss-correction view of class-dependent label noise.

## 3. Soft targets, bootstrapping, and calibration

7. **Training Deep Neural Networks on Noisy Labels with Bootstrapping** — Scott Reed, 2014 · 1009 citations · https://openalex.org/W2121056381  
   Soft/bootstrapped targets for noisy labels; conceptual neighbor to label smoothing under noise.

8. **On Calibration of Modern Neural Networks** — Chuan Guo, 2017 · 4095 citations · https://openalex.org/W2626967530  
   Documents overconfidence in modern nets; LS is often motivated as a calibration/regularization fix.

9. **Delving Deep Into Label Smoothing** — Chang–Bin Zhang, 2021 · 294 citations · https://openalex.org/W3108417339  
   Analyzes LS as regularization and proposes variants; useful for interpreting LS on small models.

## 4. Regularization for capacity-limited networks

10. **Dropout: a simple way to prevent neural networks from overfitting** — Nitish Srivastava, 2014 · 33574 citations · https://openalex.org/W2095705004  
    Classic regularizer for overfitting; sets the small-network / limited-capacity context where LS may act as another regularizer.

## From paper 3

From the 30 most-cited references of Łukasik et al. (OpenAlex W3009419078); five most relevant to LS on small nets with noisy labels (already-listed foundations skipped).

11. **Regularizing Neural Networks by Penalizing Confident Output Distributions** — Gabriel Pereyra, 2017 · 1089 citations · https://openalex.org/W2581377246  
    Confidence-penalty regularizer closely related to label smoothing; motivates soft/uncertain targets.

12. **Learning with Noisy Labels** — Nagarajan Natarajan, 2013 · 772 citations · https://openalex.org/W2113290770  
    Foundational theory for classification under label noise.

13. **Understanding deep learning requires rethinking generalization** — Chiyuan Zhang, 2016 · 3805 citations · https://openalex.org/W2950220847  
    Shows nets can memorize arbitrary labels; frames why noise robustness and regularization matter.

14. **Mixup: Beyond empirical risk minimization** — Hongyi Zhang, 2024 · 864 citations · https://openalex.org/W2963399829  
    Soft-label training via interpolated examples; a related soft-target regularizer often compared with LS.

15. **Training Convolutional Networks with Noisy Labels** — Sainbayar Sukhbaatar, 2014 · 738 citations · https://openalex.org/W1866072925  
    Early deep-learning approach to training under noisy labels.
