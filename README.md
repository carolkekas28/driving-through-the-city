# Objetivo

Desenvolver as camadas de software responsáveis por controlar um carro autônomo sobre um processador RISC-V Assembly. 

# Explicação dos arquivos

As camadas de software estão ilustradas na figura abaixo:

<img width="348" alt="Captura de Tela 2025-05-30 às 20 55 29" src="https://github.com/user-attachments/assets/4029e164-df83-4e58-98a6-21621d7a7332" />

As principais camadas de software desse projeto são:

- **ACOS:** implementada em RISC-V Assembly, esta camada é responsável pelo controle do hardware, providenciando um conjunto de serviços para a camada CoLib por meio de syscalls. Também contém o código que será executado em modo máquina.
- **CoLib:** também implementada em RISC-V Assembly, é responsável por providenciar uma interface amigável para a lógica de controle do carro, chamada de API de Controle. Esta camada é executada em modo de usuário.
- **CoLo:** esta camada cuida da lógica de controle do carro e utiliza funções definidas pela API de controle, implementada pela CoLib. Sua implementação está feita em C. 

## Camada CoLo

Como já mencionado anteriormente, essa camada tem como função principal controlar o carro, mas também deve utilizar a API para printar timestamps da chegada do carro nos checkpoints.

### Lógica de Controle do carro

O carro deve performar uma série de 3 rotas pela cidade, sendo que a rota é determinada por uma lista ligada que contém as coordenadas do próximo checkpoint e a ação que deve ser performada ao chegar lá. Essas ações podem ser:

- GoForward (0): o carro continua seguindo na mesma direção em que estava antes.
- TurnLeft (1): o carro deve virar para a esquerda.
- TurnRight (2): o carro deve virar para a direita.
- GoBack (3): o carro deve realizar uma manobra para ir para a direção contrária à de antes.
- End (4): nenhuma ação é performada, e isso indica o fim da rota.

O arquivo das listas ligadas contém os nós-cabeça A_0, B_0 e C_0.

## Camada CoLib

Essa camada implementa as rotinas da API de controle na linguagem Assembly RISC-V. As rotinas de API estão listadas no arquivo header control_api.h e foram implementadas no arquivo colib.s. Para interagir com o hardware, são utilizadas syscallls pelo código.

## Camada ACOS

Também implementada em linguagem Assembly no arquivo chamado acos.s, esta camada contém as syscalls utilizadas pelo sistema. 
