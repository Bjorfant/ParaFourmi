#include <thrust/for_each.h>
#include <thrust/device_vector.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/permutation_iterator.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/random.h> 
#include <thrust/random/uniform_real_distribution.h> 
#include <thrust/random/normal_distribution.h> 
#include <iostream>
#include <vector>
#include <cstdlib>

#define taille 200
#define debug false
#define nbEtapes 100

#define GET_LEFT(n) (n-1)
#define GET_RIGHT(n) (n+1)
#define GET_TOP(n) (n-taille)
#define GET_BOTTOM(n) (n+taille)
#define GET_FRONT(n) (n+taille*taille)
#define GET_BACK(n) (n-taille*taille)



using namespace std;
/*********************************************
MODELE DE DONNEES
*********************************************/

 typedef enum {
	VIDE=0,			//une case qui est complètement isolée des blocs pleins
	ACCESSIBLE=1,	//une case qui a au moins un voisin grain
	ACCESSIBLE_CONFLIT=2,	//une case qui est accessible et a au moins deux voisins actifs
	GRAIN_CONFLIT=3,	//une case grain qui a au moins deux voisin actifs
	GRAIN=4,		//une case de terre
	FOURMI=5,		//une fourmi
	TRANSIT=6		//une fourmi transportant un bloc
} State;


/*********************************************
FONCTIONS UTILES
*********************************************/

void printMatrix(thrust::host_vector<int> matFourmi) {
	for(int i = 0; i < taille*taille*taille; i++) {
		cout<< matFourmi[i];
		if (i%taille==taille-1)
			cout << endl;
		if (i%(taille*taille) == taille*taille-1)
			cout << endl;
	}
}

//retourne vrai si la case d'indice "index" est sur le bord gauche de la matrice
__host__ __device__
int isOnLeftBorder(int index) {
	return index%taille == 0;
}

//retourne vrai si la case d'indice "index" est sur le bord droit de la matrice 
__host__ __device__
int isOnRightBorder(int index) {
	return index%taille == taille - 1;
}

//retourne vrai si la case d'indice "index" est sur le bord supérieur de la matrice
__host__ __device__
int isOnTopBorder(int index) {
	return index%(taille*taille) - taille < 0;
}

//retourne vrai si la case d'indice "index" est sur le bord inférieur de la matrice
__host__ __device__
int isOnBottomBorder(int index) {
	return index%(taille*taille) + taille >= taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord avant de la matrice 
__host__ __device__
int isOnFrontBorder(int index) {
	return index + (taille*taille) >= taille*taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord arrière de la matrice
__host__ __device__
int isOnBackBorder(int index) {
	return index < taille*taille;
}


//décale un indice d'un vecteur d'une certaine valeur. 
//Permet de créer un vecteur de mappage pour décaller un vecteur de façon cyclique
struct moveIndex {
	const int delta, maxIndex;

	//la stucture prend le décalage à appliquer ainsi que l'indice maximum du vecteur
	moveIndex(int _delta, int _maxIndex) : delta(_delta), maxIndex(_maxIndex) {}

	__host__ __device__
	int operator()(int index){
		int val = (index + delta)%maxIndex;
		if (val<0)
			return val+maxIndex;
		else
			return val;
	}
};

__host__ __device__
int alea(int val) {
	thrust::minstd_rand rng;
	thrust::uniform_real_distribution<float> dist(0.0f, 154698.0f);
	
	rng.discard(val);
	return dist(rng);
}

__device__
int destination_alea(int index) {//, int blocAtLeft, int blocAtRight, int blocAtTop, int blocAtBottom, int blocAtFront, int blocAtBack, int type) {
	
	/*int choices[6] = {1, 2, 3, 4, 5, 6};
	int nbAccessibles = 0;
	if (!isOnLeftBorder(index)) { 
		if (blocAtLeft==type) {
			choices[nbAccessibles] = GET_LEFT(index);
			nbAccessibles++;
		}
	}
	if (!isOnRightBorder(index)) {
		if (blocAtRight==type){
			choices[nbAccessibles] = GET_RIGHT(index);
			nbAccessibles++;
		}
	}
	if (!isOnTopBorder(index)) {
		if (blocAtLeft==type){
			choices[nbAccessibles] = GET_TOP(index);
			nbAccessibles++;
		}
	}
	if (!isOnBottomBorder(index)) {
		if (blocAtLeft==type){
			choices[nbAccessibles] = GET_BOTTOM(index);
			nbAccessibles++;
		}
	}
	if (!isOnFrontBorder(index)) {
		if (blocAtLeft==type){
			choices[nbAccessibles] = GET_FRONT(index);
			nbAccessibles++;
		}
	}
	
	if (!isOnBackBorder(index)) {
		if (blocAtLeft==type){
			choices[nbAccessibles] = GET_BACK(index);
			nbAccessibles++;
		}
	}
	
	//cas où il n'y a pas de voisins accessible
	if(nbAccessibles == 0) {
		return -1;
	}
	int randomvalue = alea(index+blocAtLeft+blocAtRight+blocAtTop+blocAtBottom+blocAtFront+blocAtBack);
	int value = randomvalue % nbAccessibles;
	
	
	return choices[value];*/
	return -1;

}


__host__ __device__
int indexFourmiArrivante(int index,
			int matTransitionsBlocAtLeft,
			int matTransitionsBlocAtRight,
			int matTransitionsBlocAtTop, 
			int matTransitionsBlocAtBottom,
			int matTransitionsBlocAtFront,
			int matTransitionsBlocAtBack
) {
	if (!isOnLeftBorder(index))
		if (matTransitionsBlocAtLeft == index || matTransitionsBlocAtLeft == -1*index-2)
			return GET_LEFT(index);
	if (!isOnRightBorder(index))
		if (matTransitionsBlocAtRight == index || matTransitionsBlocAtRight == -1*index-2)
			return GET_RIGHT(index);
	if (!isOnTopBorder(index))
		if (matTransitionsBlocAtTop == index || matTransitionsBlocAtTop == -1*index-2)
			return GET_TOP(index);
	if (!isOnBottomBorder(index))
		if (matTransitionsBlocAtBottom == index || matTransitionsBlocAtBottom == -1*index-2)
			return GET_BOTTOM(index);
	if (!isOnFrontBorder(index)) // A reformuler
		if (matTransitionsBlocAtFront == index || matTransitionsBlocAtFront == -1*index-2)
			return GET_FRONT(index);
	if (!isOnBackBorder(index)) // A reformuler
		if (matTransitionsBlocAtBack == index || matTransitionsBlocAtBack == -1*index-2)
			return GET_BACK(index);
	return -1;
}


//genère une matrice aléatoire constituée de grains et de bloc accessibles 
//cette matrice nécéssite d'être retravaillée par la suite pour la cohérence des données
struct genereMatrix {
	__host__ __device__
	int operator()(int bloc) {
		
		int states[] = {ACCESSIBLE, GRAIN};
		
		int x = bloc %2;
		return states[x];
	}
};


//retourne le nombre de voisins actifs dans l'entourage de la case à la position "index" dans la matrice
//un voisin actif est une fourmi simple ou une fourmi transportant un bloc
__host__ __device__
int getNbVoisinsActifs(int index, int left, int right, int top, int bottom, int front, int back) {
	int nb = 0;
	if (!isOnLeftBorder(index)) {
		if (left == FOURMI || left == TRANSIT) 
			nb++;
	}
	if (!isOnRightBorder(index)) {
		if (right == FOURMI || right == TRANSIT) 
			nb++;
	}
	if (!isOnTopBorder(index)) {
		if (top == FOURMI || top == TRANSIT) 
			nb++;
	}
	if (!isOnBottomBorder(index)) {
		if (bottom == FOURMI || bottom == TRANSIT) 
			nb++;
	}
	if (!isOnFrontBorder(index)) {
		if (front == FOURMI || front == TRANSIT) 
			nb++;
	}
	if(!isOnBackBorder(index)) {
		if (back == FOURMI || back == TRANSIT) 
			nb++;
	} 
	return nb;
}

//retourne vrai si la case d'indice "index" est accessible 
__host__ __device__
bool isAccessible(int index, int left, int right, int top, int bottom, int front, int back) {
	
	bool isAccessible = false;
	
	if (!isOnLeftBorder(index)) { 
		isAccessible |= left == GRAIN || left == GRAIN_CONFLIT;
	}
	if (!isOnRightBorder(index)) {
		isAccessible |= right == GRAIN || right == GRAIN_CONFLIT;
	}
	if (!isOnTopBorder(index)) {
		isAccessible |= top == GRAIN || top == GRAIN_CONFLIT;
	}
	if (!isOnBottomBorder(index)) {
		isAccessible |= bottom == GRAIN || bottom == GRAIN_CONFLIT;
	}
	if (!isOnFrontBorder(index)) {
		isAccessible |= front == GRAIN || front == GRAIN_CONFLIT;
	}
	if (!isOnBackBorder(index)) {
		isAccessible |= back == GRAIN || back == GRAIN_CONFLIT;
	}
	return isAccessible;
}



/*********************************************
FONCTIONS PRINCIPALES DES BOUCLES DE SIMULATION
*********************************************/

//la fonction updateStates sert à garder l'intégrité des données présentes dans la matrice
//on vérifie ici que tous les états sont cohérents vis à vis du modèle adopté
//elle prend en paramètres un tuple de 8 valeurs dont :
//- l'indice auquel on se trouve dans la matrice
//- la valeur du bloc courant 
//- les 6 valeurs des des blocs voisins
struct updateStates {

template <typename Tuple>
__host__ __device__
	void operator()(Tuple t) {
		int index = thrust::get<0>(t);
		int bloc = thrust::get<1>(t);
		int blocAtLeft = thrust::get<2>(t);
		int blocAtRight = thrust::get<3>(t);
		int blocAtTop = thrust::get<4>(t);
		int blocAtBottom = thrust::get<5>(t);
		int blocAtFront = thrust::get<6>(t);
		int blocAtBack = thrust::get<7>(t);
		
		//dans le cas ou le bloc courant est vide ou accessible on vérifie que ses prorpiétés correspondent bien à son état
		if(bloc == ACCESSIBLE || bloc == ACCESSIBLE_CONFLIT) {
			if(!isAccessible(index, blocAtLeft, blocAtRight, blocAtTop, blocAtBottom, blocAtFront, blocAtBack))
				thrust::get<8>(t) = VIDE; 
			else {
				if(getNbVoisinsActifs(index, blocAtLeft, blocAtRight, blocAtTop, blocAtBottom, blocAtFront, blocAtBack) > 1)
					thrust::get<8>(t) = ACCESSIBLE_CONFLIT;
				else
					thrust::get<8>(t) = ACCESSIBLE;
			}
		} else if (bloc == GRAIN || bloc == GRAIN_CONFLIT) {
			//Dans le cas ou le bloc est un grain ou du plein il faut vérifier que ses propriétés correspondent bien à son état 
			if (getNbVoisinsActifs(index, blocAtLeft, blocAtRight, blocAtTop, blocAtBottom, blocAtFront, blocAtBack) > 1)
				thrust::get<8>(t) = GRAIN_CONFLIT;
			else
				thrust::get<8>(t) = GRAIN;
		} else {
			//si le bloc est de type fourmi ou transit alors il ne change pas d'état 
			//on retourne sa valeur inchangée
			thrust::get<8>(t) = bloc;
		}
	}
	};


/*Cette fonction permet de determiner les intention d'action de toutes les fourmis présentes dans la matrice.
Les actions ne sont pas effectuées sur la matrice principale, elles sont simplement renseigner.
On créé ainsi une matrice supplémentaire indiquant les mouvements qui interviendront à l'étape suivante.
*/
struct transition1 {

	template <typename Tuple>
	__device__
	int operator() (Tuple t) {
	
		int index = thrust::get<0>(t);
		int bloc = thrust::get<1>(t);
		int blocAtLeft = thrust::get<2>(t);
		int blocAtRight = thrust::get<3>(t);
		int blocAtTop = thrust::get<4>(t);
		int blocAtBottom = thrust::get<5>(t);
		int blocAtFront = thrust::get<6>(t);
		int blocAtBack = thrust::get<7>(t);
		
		int choix = alea(index+bloc+blocAtLeft+blocAtRight+blocAtTop+blocAtBottom+blocAtFront+blocAtBack) %2;
		if (bloc==FOURMI || bloc==TRANSIT) {
		
			if (choix==0) {//Déplacement
				return destination_alea(index);//,blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack, ACCESSIBLE);
			}
			else if (choix==1 && bloc == FOURMI) { //Ramassage
				//vector <int> tmp;
				//tmp.push_back(GRAIN);
				//vector <int> voisins = listeVoisins(index, tmp);
				return destination_alea(index,blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack, GRAIN);
			}
			else if (choix==1 && bloc == TRANSIT) { //Dépot
				if (destination_alea(index,blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack, ACCESSIBLE)==-1)
					return -1;
				else
					return -1*destination_alea(index,blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack, ACCESSIBLE)-2;
			}
		}
		else
			return -1;
		return -1;
	}
};


struct transition2 {

	template <typename Tuple1,typename Tuple2>
	__device__
	int operator() (Tuple1 t1, Tuple2 t2) {
		
		/*int index = thrust::get<0>(t1);
		int blocOriginal = thrust::get<1>(t1); // matFourmi[index]
		
		
		//int blocTransitions = thrust::get<1>(t); //matTransitions[indexFourmi]
		//int blocArrivee =  thrust::get<2>(t); // matFourmi[indexFourmi]
		
		int matFourmiBlocAtLeft = thrust::get<2>(t1);
		int matFourmiBlocAtRight = thrust::get<3>(t1);
		int matFourmiBlocAtTop = thrust::get<4>(t1);
		int matFourmiBlocAtBottom = thrust::get<5>(t1);
		int matFourmiBlocAtFront = thrust::get<6>(t1);
		int matFourmiBlocAtBack = thrust::get<7>(t1);
		
		int blocTransition = thrust::get<0>(t2);
		int matTransitionsBlocAtLeft = thrust::get<1>(t2);
		int matTransitionsBlocAtRight = thrust::get<2>(t2);
		int matTransitionsBlocAtTop = thrust::get<3>(t2);
		int matTransitionsBlocAtBottom = thrust::get<4>(t2);
		int matTransitionsBlocAtFront = thrust::get<5>(t2);
		int matTransitionsBlocAtBack = thrust::get<6>(t2);
	
		//récupère, si elle existe, la position de la fourmi qui arrive sur la case courante
		int indexFourmi = indexFourmiArrivante(index, matTransitionsBlocAtLeft, matTransitionsBlocAtRight, matTransitionsBlocAtTop, matTransitionsBlocAtBottom, matTransitionsBlocAtFront, matTransitionsBlocAtBack);
		
		int isDeparture = blocTransition != -1;
		bool isArrival = indexFourmi != -1;
		
		int blocTransitions = 0;
		int blocArrivee = 0;
		
		if (indexFourmi == GET_LEFT(index)) {
			blocTransitions = matTransitionsBlocAtLeft;
			blocArrivee = matFourmiBlocAtLeft;
		}
		else if (indexFourmi == GET_RIGHT(index)) {
			blocTransitions = matTransitionsBlocAtRight;
			blocArrivee = matFourmiBlocAtRight;
		}
		else if (indexFourmi == GET_TOP(index)) {
			blocTransitions = matTransitionsBlocAtTop;
			blocArrivee = matFourmiBlocAtTop;
		}
		else if (indexFourmi == GET_BOTTOM(index)) {
			blocTransitions = matTransitionsBlocAtBottom;
			blocArrivee = matFourmiBlocAtBottom;
		}
		else if (indexFourmi == GET_FRONT(index)) {
			blocTransitions = matTransitionsBlocAtFront;
			blocArrivee = matFourmiBlocAtFront;
		}
		else if (indexFourmi == GET_BACK(index)) {
			blocTransitions = matTransitionsBlocAtBack;
			blocArrivee = matFourmiBlocAtBack;
		}

		if (isDeparture) {
			if (blocOriginal > -1) //cas déplacement
				return ACCESSIBLE;
			else	//cas dépot
				return GRAIN;
		}
		else if (isArrival) {
			if (blocTransitions > -1) { //cas déplacement
				if (blocOriginal == ACCESSIBLE) //cas déplacement simple
					return blocArrivee; 
				else if (blocOriginal == GRAIN) //cas ramassage
					return TRANSIT;
			}
			else if (blocTransitions < -1)	//cas dépot
				return FOURMI;
		}
		else
			return blocOriginal;*/
		
		return 1;
	}
};


int main() {
	
	srand ( time(NULL) );
	clock_t endwait;
	
	endwait = clock();
	
	// Génération de la matrice
	thrust::host_vector<int> matFourmiHost(taille*taille*taille);
	
	thrust::generate(matFourmiHost.begin(), matFourmiHost.end(), rand);
	thrust::transform(matFourmiHost.begin(), matFourmiHost.end(), matFourmiHost.begin(), genereMatrix());
	
	// Placement d'une fourmi
	int nbFourmis = 1;
	for (int i = 0 ; i<nbFourmis ; i++) {
		int randvalue = 4;//rand() % taille*taille*taille;
		matFourmiHost[randvalue] = FOURMI;
	}

	thrust::device_vector<int> matFourmi = matFourmiHost;
	// Création des matrices décalées
	int tailleTotale = matFourmi.size();
	thrust::counting_iterator<int> begin(0);
	thrust::counting_iterator<int> end(tailleTotale);

	thrust::device_vector <int> rightIndexes(tailleTotale);
	thrust::device_vector <int> leftIndexes(tailleTotale);
	thrust::device_vector <int> topIndexes(tailleTotale);
	thrust::device_vector <int> bottomIndexes(tailleTotale);
	thrust::device_vector <int> frontIndexes(tailleTotale);
	thrust::device_vector <int> backIndexes(tailleTotale);
	
	//création des vecteurs contenant les indices décalés du vecteur principal
	thrust::transform(begin, end, leftIndexes.begin(), moveIndex(-1 ,tailleTotale));
	thrust::transform(begin, end, rightIndexes.begin(), moveIndex(1 ,tailleTotale));
	thrust::transform(begin, end, topIndexes.begin(), moveIndex(-taille ,tailleTotale));
	thrust::transform(begin, end, bottomIndexes.begin(), moveIndex(taille ,tailleTotale));
	thrust::transform(begin, end, frontIndexes.begin(), moveIndex(taille*taille ,tailleTotale));
	thrust::transform(begin, end, backIndexes.begin(), moveIndex(-taille*taille ,tailleTotale));
	
	
	//Première mise à jour de la matrice
	//ici, on créé des listes décalées pour pouvoir acceder à tous les éléments voisins d'un élément particulier
	thrust::for_each(
		thrust::make_zip_iterator(
			thrust::make_tuple(
				begin,
				matFourmi.begin(),
				thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.begin()), 
				matFourmi.begin()
			)
		),
		thrust::make_zip_iterator(
			thrust::make_tuple(
				end,
				matFourmi.end(), 
				thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end()), 
				matFourmi.end()
			)
		),
		updateStates()
	);
	
	// Création de la matrice intermédiaire
	thrust::device_vector <int> matTransitions(tailleTotale);
	thrust::fill(matTransitions.begin(), matTransitions.end(), 0);

	if (debug) {
		cout << "Matrice initiale" << endl;
		printMatrix(matFourmi);
	}
	
	// Demande du nombre d'étapes à l'utilisateur
	//int nbEtapes = 1;
	//cout << "Combien d'etapes voulez vous realiser ?" << endl;
	//cin >> nbEtapes;
	
	thrust::device_vector<int> matFourmi2(tailleTotale);
	
	
	
	cout << "Temps écoulé : " << clock() - endwait << endl;
	endwait = clock();
	
	// Boucle principale des étapes
	for (int i=0 ; i<nbEtapes ; i++) {
		if (debug)
			cout << "Etape " << i << endl;
		
		// Transition 1
		thrust::transform(
			thrust::make_zip_iterator(
				thrust::make_tuple(
					begin,
					matFourmi.begin(),
					thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.begin())
				)
			),
			thrust::make_zip_iterator(
				thrust::make_tuple(
					end,
					matFourmi.end(), 
					thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end())
				)
			),
			matTransitions.begin(),
			transition1()
		);
		
		if(debug) {
			cout << "\nMatrice temporaire" << endl;
			printMatrix(matTransitions);
		}
	
		// Transition 2
		
		thrust::transform(
			thrust::make_zip_iterator(
					thrust::make_tuple(
						begin,
						matFourmi.begin(),
						thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.begin()), 
						thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.begin()), 
						thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.begin()), 
						thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.begin()), 
						thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.begin()), 
						thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.begin())
					)
			),
			thrust::make_zip_iterator(
					thrust::make_tuple(
						end,
						matFourmi.end(),
						thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
						thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
						thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
						thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
						thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
						thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end())
					)
			),
			thrust::make_zip_iterator(
					thrust::make_tuple(
						matTransitions.begin(),
						thrust::make_permutation_iterator(matTransitions.begin(), leftIndexes.begin()), 
						thrust::make_permutation_iterator(matTransitions.begin(), rightIndexes.begin()), 
						thrust::make_permutation_iterator(matTransitions.begin(), topIndexes.begin()), 
						thrust::make_permutation_iterator(matTransitions.begin(), bottomIndexes.begin()), 
						thrust::make_permutation_iterator(matTransitions.begin(), frontIndexes.begin()), 
						thrust::make_permutation_iterator(matTransitions.begin(), backIndexes.begin())
					)
			),
			matFourmi2.begin(),
			transition2()
		);
		
		//Mise à jour périodique
		//ici, on créé des listes décalées pour pouvoir acceder à tous les éléments voisins d'un élément particulier
		thrust::for_each(
			thrust::make_zip_iterator(
				thrust::make_tuple(
					begin,
					matFourmi2.begin(),
					thrust::make_permutation_iterator(matFourmi2.begin(), leftIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), rightIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), topIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), bottomIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), frontIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), backIndexes.begin()), 
					matFourmi.begin()
				)
			),
			thrust::make_zip_iterator(
				thrust::make_tuple(
					end,
					matFourmi2.end(), 
					thrust::make_permutation_iterator(matFourmi2.begin(), leftIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), rightIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), topIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), bottomIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), frontIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi2.begin(), backIndexes.end()), 
					matFourmi.end()
				)
			),
			updateStates()
		);
		
		if (debug) {
			printMatrix(matFourmi);
			system("pause");
		}
			
	}
	
	//t2 = clock() - t1;
	cout << "Temps total : " << (clock() - endwait) << endl;
	cout << "Moyenne de Temps écoulé : " << ((float)(clock() - endwait))/nbEtapes << endl;

	return 0;
}

/*
nvcc --machine 32 -ccbin "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin"  -I "C:\Program Files (x86)\NVIDIA GPU Computing Toolkit\CUDA\v3.2\include" testpara.cu -o testpara
*/