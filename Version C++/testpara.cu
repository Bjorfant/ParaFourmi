#include <thrust/for_each.h>
#include <thrust/device_vector.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/permutation_iterator.h>
#include <thrust/iterator/zip_iterator.h>
#include <iostream>
#include <vector>
#include <cstdlib>

#define taille 3

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
		cout<< matFourmi[i] << endl;
	}
}

//retourne vrai si la case d'indice "index" est sur le bord gauche de la matrice

int isOnLeftBorder(int index) {
	return index%taille == 0;
}

//retourne vrai si la case d'indice "index" est sur le bord droit de la matrice 

int isOnRightBorder(int index) {
	return index%taille == taille - 1;
}

//retourne vrai si la case d'indice "index" est sur le bord supérieur de la matrice

int isOnTopBorder(int index) {
	return index%(taille*taille) - taille < 0;
}

//retourne vrai si la case d'indice "index" est sur le bord inférieur de la matrice

int isOnBottomBorder(int index) {
	return index%(taille*taille) + taille >= taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord avant de la matrice 

int isOnFrontBorder(int index) {
	return index + (taille*taille) >= taille*taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord arrière de la matrice

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
		return (index + delta)%maxIndex;
	}
};


int deplacement_alea(vector <int> voisins) {
	if (voisins.size() >= 1)
		return voisins[0];
	else
		return -1;
}

int deplacement_alea_new(int blocAtLeft, int blocAtRight, int blocAtTop, int blocAtBottom, int blocAtFront, int blocAtBack) {
	return blocAtLeft;
}


/*
int indexFourmiVoisine(int index, , vector<int> &matTransitions) {
	if (!isOnRightBorder(index))
		if (matTransitions[index+1] == index || matTransitions[index+1] == -1*index-2)
			return index+1;
	if (!isOnLeftBorder(index))
		if (matTransitions[index-1] == index || matTransitions[index-1] == -1*index-2)
			return index-1;
	if (!isOnTopBorder(index))
		if (matTransitions[index-taille] == index || matTransitions[index-taille] == -1*index-2)
			return index-taille;
	if (!isOnBottomBorder(index))
		if (matTransitions[index+taille] == index || matTransitions[index+taille] == -1*index-2)
			return index+taille;
	if (!isOnFrontBorder(index)) // A reformuler
		if (matTransitions[index+taille**2] == index || matTransitions[index+taille**2] == -1*index-2)
			return index+taille**2;
	if (!isOnBackBorder(index)) // A reformuler
		if (matTransitions[index-taille**2] == index || matTransitions[index-taille**2] == -1*index-2)
			return index-taille**2;
	return -1;
}*/


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
bool isAccessible(int index, int left, int right, int top, int bottom, int front, int back) {
	if (!isOnLeftBorder(index)) { 
		return left == GRAIN || left == GRAIN_CONFLIT;
	}
	if (!isOnRightBorder(index)) {
		return right == GRAIN || right == GRAIN_CONFLIT;
	}
	if (!isOnTopBorder(index)) {
		return top == GRAIN || top == GRAIN_CONFLIT;
	}
	if (!isOnBottomBorder(index)) {
		return bottom == GRAIN || bottom == GRAIN_CONFLIT;
	}
	if (!isOnFrontBorder(index)) {
		return front == GRAIN || front == GRAIN_CONFLIT;
	}
	if (!isOnBackBorder(index)) {
		return back == GRAIN || back == GRAIN_CONFLIT;
	}
	return false;
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
	__host__ __device__
	void operator() (Tuple t) {
	
		int bloc = thrust::get<0>(t);
		int blocAtLeft = thrust::get<1>(t);
		int blocAtRight = thrust::get<2>(t);
		int blocAtTop = thrust::get<3>(t);
		int blocAtBottom = thrust::get<4>(t);
		int blocAtFront = thrust::get<5>(t);
		int blocAtBack = thrust::get<6>(t);
		
		int choix = rand() % 2;
		if (bloc==FOURMI || bloc==TRANSIT) {
			if (choix==0) { //Déplacement
				thrust::get<7>(t) = deplacement_alea_new(blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack);
			}
			else if (choix==1 && bloc == FOURMI) { //Ramassage
				//vector <int> tmp;
				//tmp.push_back(GRAIN);
				//vector <int> voisins = listeVoisins(index, tmp);
				thrust::get<7>(t) = deplacement_alea_new(blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack);
			}
			else if (choix==1 && bloc == TRANSIT) { //Dépot
				if (deplacement_alea_new(blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack)==-1)
					thrust::get<7>(t) = -1;
				else
					thrust::get<7>(t) = -1*deplacement_alea_new(blocAtLeft,blocAtRight,blocAtTop,blocAtBottom,blocAtFront,blocAtBack)-2;
			}
		}
		else
			thrust::get<7>(t) = -1;
	}
};


struct transition2 {

	template <typename Tuple>
	__host__ __device__
	void operator() (Tuple t) {
	
		int blocOriginal = thrust::get<0>(t); // matFourmi[index]
		int blocTransitions = thrust::get<1>(t); //matTransitions[indexFourmi]
		int blocArrivee =  thrust::get<2>(t); // matFourmi[indexFourmi]
		int blocAtLeft = thrust::get<3>(t);
		int blocAtRight = thrust::get<4>(t);
		int blocAtTop = thrust::get<5>(t);
		int blocAtBottom = thrust::get<6>(t);
		int blocAtFront = thrust::get<7>(t);
		int blocAtBack = thrust::get<8>(t);
	
		bool isDeparture = blocOriginal != -1;
		int indexFourmi = indexFourmiVoisine(index);
		bool isArrival = indexFourmi != -1;

		if (isDeparture) {
			if (bloc > -1) //cas déplacement
				thrust::get<9>(t) = ACCESSIBLE;
			else	//cas dépot
				thrust::get<9>(t) = GRAIN;
		}
		else if (isArrival) {
			if (blocTransitions > -1) { //cas déplacement
				if (blocOriginal == ACCESSIBLE) //cas déplacement simple
					thrust::get<9>(t) = blocArrivee; 
				else if (blocOriginal == GRAIN) //cas ramassage
					thrust::get<9>(t) = TRANSIT;
			}
			else if (blocTransitions < -1)	//cas dépot
				thrust::get<9>(t) = FOURMI;
		}
		else
			thrust::get<9>(t) = blocOriginal;
	}
};


int main() {
	
	srand ( time(NULL) );
	clock_t t1;
	clock_t t2;
	t1 = clock();
	
	
	// Génération de la matrice
	thrust::host_vector<int> matFourmi(taille*taille*taille);
	thrust::generate(matFourmi.begin(), matFourmi.end(), rand);
	thrust::transform(matFourmi.begin(), matFourmi.end(), matFourmi.begin(), genereMatrix());
	
	// Placement d'une fourmi
	int nbFourmis = 1;
	for (int i = 0 ; i<nbFourmis ; i++) {
		int randvalue = rand() % taille*taille*taille;
		matFourmi[randvalue] = FOURMI;
	}
	

	// Création des matrices décalées
	int tailleTotale = matFourmi.size();
	thrust::counting_iterator<int> begin(0);
	thrust::counting_iterator<int> end(tailleTotale);

	thrust::host_vector <int> rightIndexes(tailleTotale);
	thrust::host_vector <int> leftIndexes(tailleTotale);
	thrust::host_vector <int> topIndexes(tailleTotale);
	thrust::host_vector <int> bottomIndexes(tailleTotale);
	thrust::host_vector <int> frontIndexes(tailleTotale);
	thrust::host_vector <int> backIndexes(tailleTotale);
	
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
	thrust::host_vector <int> matTransitions;
	thrust::fill(matTransitions.begin(), matTransitions.end(), 0);

	cout << "Matrice initiale" << endl;
	printMatrix(matFourmi);
	
	// Demande du nombre d'étapes à l'utilisateur
	int nbEtapes;
	cout << "Combien d'etapes voulez vous realiser ?" << endl;
	cin >> nbEtapes;
	
	
	// Boucle principale des étapes
	for (int i=0 ; i<nbEtapes ; i++) {
		cout << "Etape " << i << endl;
		
		cout << "\nMatrice temps" << i << endl;
		
		// Transition 1
		thrust::for_each(
			thrust::make_zip_iterator(
				thrust::make_tuple(
					matFourmi.begin(),
					thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.begin()), 
					thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.begin()), 
					matTransitions.begin()
				)
			),
			thrust::make_zip_iterator(
				thrust::make_tuple(
					matFourmi.end(), 
					thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end()), 
					matTransitions.end()
				)
			),
			transition1()
		);
		cout << "\nMatrice temporaire" << endl;
		printMatrix(matTransitions);
		
		// Transition 2
		/*
		thrust::for_each(
			thrust::make_zip_iterator(
				thrust::make_tuple(
					matTransitions.begin(),
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
					matTransitions.end(), 
					thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
					thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end()), 
					matFourmi.end()
				)
			),
			transition1()
		);*/
		
		//matFourmi = updateStatesHost(matFourmi);
		printMatrix(matFourmi);
		
		system("pause");
	}
	
	t2 = clock() - t1;
	cout << "Temps écoulé : " << t2 << endl;

	return 0;
}

/*
nvcc --machine 32 -ccbin "C:\Program Files\Microsoft Visual Studio 10.0\VC\bin"  -I "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.0\include" testpara.cu -o testpara
*/
