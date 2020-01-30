// Practica 5: Sergio Muñumer Blázquez
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <netinet/ip.h>
#include <netinet/in.h>
#include <string.h>  
#define MAX 1024 
  
int main(int argc, char *argv[]) { 
     
    char buffer[MAX];  
	struct servent *serv;	
	struct sockaddr_in servaddr;					//Creacion de la estructura relacionada con el servidor
	inet_aton(argv[1], &servaddr.sin_addr);			//Asigno argumento de programa '1' (IP) a la estructura sockaddr_in "servadrr"
	
	if (argc<2) {									//Comprueba si el número de argumentos es inválido
		printf("Numero de argumentos inválido\n");
		exit(EXIT_FAILURE);
	}
	else if(argc==2){								//Si no nos dan puerto, buscamos el puerto por defecto
		printf("Puerto no especificado, buscando puerto por defecto para DAYTIME...\n");
		//
		serv=(servent)getservbyname("DAYTIME","udp");
		servaddr.sin_port = serv -> s_port;
		if (serv == NULL){
			printf("Error al obtener puerto\n");
			perror("\nserv");
			exit(EXIT_FAILURE);
		}
	}
	else if (argc==4 && (strcmp("-p",argv[2])==0)){	//Asignamos el puerto dado por el usuario a la estructura del servidor
		int puerto;
		sscanf(argv[3],"%d", &puerto);
		servaddr.sin_port = htons(puerto);
	}
	
    int sockfd;												//Creamos descriptor socket y definimos su tipo
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) { 	//Comprobamos la operacion, si falla, salimos
        perror("\nsocket()"); 
        exit(EXIT_FAILURE); 
    } 
  
   // memset(&servaddr, 0, sizeof(servaddr)); 
  
   
	struct sockaddr_in client;								 //Creacion de la estructura relacionada con el cliente
	client.sin_family=AF_INET;
	client.sin_port=0;
	client.sin_addr.s_addr= INADDR_ANY;
      
    int erro;
	if (bind(sockfd, (struct sockaddr*) &client, sizeof(client)) < 0){
		printf("Fallo al enlazar el socket\n");
		perror("\nbind()");
		exit (EXIT_FAILURE);
	}
	char *cadena = "cadenaArbitraria";
	if(sendto(sockfd, cadena, sizeof(cadena),0, (struct sockaddr*)&servaddr, sizeof(servaddr))<0){
		printf("Fallo en el envio\n");
		perror("\nsendto()");
		exit(EXIT_FAILURE);
	}
  
    //Conexion con el servidor
	socklen_t len = sizeof(servaddr);
	if(recvfrom(sockfd, buffer, MAX, 0,(struct sockaddr*)&client,&len) < 0){
		perror("\nrecvfrom()");
		exit(EXIT_FAILURE);
	}

	//Imprimimos la cita
	printf("%s\n",buffer);
	exit (EXIT_SUCCESS);
	close(sockfd);
    return 0; 
} 