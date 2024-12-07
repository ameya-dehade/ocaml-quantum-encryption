This folder deals with the implementation and logic of the Kyber algorithm.
- The modules Polynomial, PolyMat and Kyber are implemented through functors in this folder
- All modules and module functions are tested with 90%+ code coverage
- Polynomial module has basic operation functions, reduction (for modulus) functions, and other helper functions for testing
- Similarly, PolyMat module has basic operation functions, reduction (for modulus) functions, and other helper functions for testing. Additionally it also contains multiplication, transpose and dot product operations
- Kyber module used Polynomial and PolyMat to implement Kyber as per the research paper
