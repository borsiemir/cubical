{-

Basic theory about h-levels/n-types:

- Basic properties of isContr, isProp and isSet (definitions are in Prelude)

- Hedberg's theorem can be found in Cubical/Relation/Nullary/DecidableEq

-}
{-# OPTIONS --cubical --safe #-}
module Cubical.Foundations.HLevels where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Function
open import Cubical.Foundations.Structure
open import Cubical.Foundations.FunExtEquiv
open import Cubical.Foundations.GroupoidLaws
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.Path
open import Cubical.Foundations.Transport
open import Cubical.Foundations.HAEquiv      using (congEquiv)
open import Cubical.Foundations.Univalence   using (ua; univalence)

open import Cubical.Data.Sigma using (ΣPathP; sigmaPath→pathSigma; pathSigma≡sigmaPath; _Σ≡T_)
open import Cubical.Data.Nat   using (ℕ; zero; suc; _+_; +-zero; +-comm)

private
  variable
    ℓ ℓ' : Level
    A : Type ℓ
    B : A → Type ℓ
    x y : A
    n : ℕ

isOfHLevel : ℕ → Type ℓ → Type ℓ
isOfHLevel 0 A = isContr A
isOfHLevel 1 A = isProp A
isOfHLevel (suc (suc n)) A = (x y : A) → isOfHLevel (suc n) (x ≡ y)

HLevel : ∀ ℓ → ℕ → Type (ℓ-suc ℓ)
HLevel ℓ n = TypeWithStr ℓ (isOfHLevel n)

hProp hSet hGroupoid h2Groupoid : ∀ ℓ → Type (ℓ-suc ℓ)
hProp      ℓ = HLevel ℓ 1
hSet       ℓ = HLevel ℓ 2
hGroupoid  ℓ = HLevel ℓ 3
h2Groupoid ℓ = HLevel ℓ 4

-- lower h-levels imply higher h-levels

isOfHLevelSuc : (n : ℕ) → isOfHLevel n A → isOfHLevel (suc n) A
isOfHLevelSuc 0 = isContr→isProp
isOfHLevelSuc 1 = isProp→isSet
isOfHLevelSuc (suc (suc n)) h a b = isOfHLevelSuc (suc n) (h a b)

isOfHLevelPlus : (m : ℕ) → isOfHLevel n A → isOfHLevel (m + n) A
isOfHLevelPlus zero hA = hA
isOfHLevelPlus (suc m) hA = isOfHLevelSuc _ (isOfHLevelPlus m hA)

isContr→isOfHLevel : (n : ℕ) → isContr A → isOfHLevel n A
isContr→isOfHLevel {A = A} n cA = subst (λ m → isOfHLevel m A) (+-zero n) (isOfHLevelPlus n cA)

isProp→isOfHLevelSuc : (n : ℕ) → isProp A → isOfHLevel (suc n) A
isProp→isOfHLevelSuc {A = A} n pA = subst (λ m → isOfHLevel m A) (+-comm n 1) (isOfHLevelPlus n pA)

-- hlevel of path and dependent path types

isProp→isContrPath : isProp A → (x y : A) → isContr (x ≡ y)
isProp→isContrPath h x y = h x y , isProp→isSet h x y _

isContr→isContrPath : isContr A → (x y : A) → isContr (x ≡ y)
isContr→isContrPath cA = isProp→isContrPath (isContr→isProp cA)

isOfHLevelPath' : (n : ℕ) → isOfHLevel (suc n) A → (x y : A) → isOfHLevel n (x ≡ y)
isOfHLevelPath' 0 = isProp→isContrPath
isOfHLevelPath' (suc n) h x y = h x y

isOfHLevelPath : (n : ℕ) → isOfHLevel n A → (x y : A) → isOfHLevel n (x ≡ y)
isOfHLevelPath 0 h x y = isContr→isContrPath h x y
isOfHLevelPath (suc n) h x y = isOfHLevelSuc n (isOfHLevelPath' n h x y)

isOfHLevelPathP' : {A : I → Type ℓ} (n : ℕ)
                   → (∀ i → isOfHLevel (suc n) (A i))
                   → (x : A i0) (y : A i1) → isOfHLevel n (PathP A x y)
isOfHLevelPathP' {A = A} n h x y = transport⁻ (λ i → isOfHLevel n (PathP≡Path A x y i))
                                              (isOfHLevelPath' n (h i1) _ _)

isOfHLevelPathP : {A : I → Type ℓ} (n : ℕ)
                  → (∀ i → isOfHLevel n (A i))
                  → (x : A i0) (y : A i1) → isOfHLevel n (PathP A x y)
isOfHLevelPathP {A = A} n h x y = transport⁻ (λ i → isOfHLevel n (PathP≡Path A x y i))
                                             (isOfHLevelPath n (h i1) _ _)

isProp→isContrPathP : {A : I → Type ℓ} → (∀ i → isProp (A i))
                                       → (x : A i0) (y : A i1) → isContr (PathP A x y)
isProp→isContrPathP h x y = isProp→PathP h x y , isOfHLevelPathP 1 h x y _

-- h-level of isOfHLevel

isPropIsOfHLevel : (n : ℕ) → isProp (isOfHLevel n A)
isPropIsOfHLevel 0 = isPropIsContr
isPropIsOfHLevel 1 = isPropIsProp
isPropIsOfHLevel (suc (suc n)) f g i a b =
  isPropIsOfHLevel (suc n) (f a b) (g a b) i

isPropIsSet : isProp (isSet A)
isPropIsSet = isPropIsOfHLevel 2

-- Fillers for cubes from h-level

isSet→isSet' : isSet A → isSet' A
isSet→isSet' {A = A} Aset a₀₋ a₁₋ a₋₀ a₋₁ =
  transport⁻ (PathP≡Path (λ i → a₋₀ i ≡ a₋₁ i) a₀₋ a₁₋) (Aset _ _ _ _)

isSet'→isSet : isSet' A → isSet A
isSet'→isSet {A = A} Aset' x y p q = Aset' p q refl refl

isGroupoid→isGroupoid' : isGroupoid A → isGroupoid' A
isGroupoid→isGroupoid' {A = A} Agpd a₀₋₋ a₁₋₋ a₋₀₋ a₋₁₋ a₋₋₀ a₋₋₁ =
  transport⁻ (PathP≡Path (λ i → Square (a₋₀₋ i) (a₋₁₋ i) (a₋₋₀ i) (a₋₋₁ i)) a₀₋₋ a₁₋₋)
    (isGroupoid→isPropSquare _ _ _ _ _ _)
  where
  isGroupoid→isPropSquare :
    {a₀₀ a₀₁ : A} (a₀₋ : a₀₀ ≡ a₀₁)
    {a₁₀ a₁₁ : A} (a₁₋ : a₁₀ ≡ a₁₁)
    (a₋₀ : a₀₀ ≡ a₁₀) (a₋₁ : a₀₁ ≡ a₁₁)
    → isProp (Square a₀₋ a₁₋ a₋₀ a₋₁)
  isGroupoid→isPropSquare a₀₋ a₁₋ a₋₀ a₋₁ =
    transport⁻
      (cong isProp (PathP≡Path (λ i → a₋₀ i ≡ a₋₁ i) a₀₋ a₁₋))
      (Agpd _ _ _ _)

isGroupoid'→isGroupoid : isGroupoid' A → isGroupoid A
isGroupoid'→isGroupoid Agpd' x y p q r s = Agpd' r s refl refl refl refl

-- hlevels are preserved by retracts (and consequently equivalences)

isContrRetract
  : ∀ {B : Type ℓ}
  → (f : A → B) (g : B → A)
  → (h : retract f g)
  → (v : isContr B) → isContr A
isContrRetract f g h (b , p) = (g b , λ x → (cong g (p (f x))) ∙ (h x))

isPropRetract
  : {B : Type ℓ}
  (f : A → B) (g : B → A)
  (h : (x : A) → g (f x) ≡ x)
  → isProp B → isProp A
isPropRetract f g h p x y i =
  hcomp
    (λ j → λ
      { (i = i0) → h x j
      ; (i = i1) → h y j})
    (g (p (f x) (f y) i))

isOfHLevelRetract
  : (n : ℕ) {B : Type ℓ}
  (f : A → B) (g : B → A)
  (h : (x : A) → g (f x) ≡ x)
  → isOfHLevel n B → isOfHLevel n A
isOfHLevelRetract 0 = isContrRetract
isOfHLevelRetract 1 = isPropRetract
isOfHLevelRetract (suc (suc n)) f g h ofLevel x y =
  isOfHLevelRetract (suc n)
    (cong f)
    (λ q i →
      hcomp
        (λ j → λ
          { (i = i0) → h x j
          ; (i = i1) → h y j})
        (g (q i)))
    (λ p k i →
      hcomp
        (λ j → λ
          { (i = i0) → h x (j ∨ k)
          ; (i = i1) → h y (j ∨ k)
          ; (k = i1) → p i})
        (h (p i) k))
    (ofLevel (f x) (f y))

isOfHLevelRespectEquiv : {A : Type ℓ} {B : Type ℓ'} → (n : ℕ) → A ≃ B → isOfHLevel n A → isOfHLevel n B
isOfHLevelRespectEquiv n eq = isOfHLevelRetract n (invEq eq) (eq .fst) (retEq eq)

-- h-level of Σ-types

isContrΣ
  : isContr A
  → ((x : A) → isContr (B x))
  → isContr (Σ[ x ∈ A ] B x)
isContrΣ {A = A} {B = B} (a , p) q =
  let h : (x : A) (y : B x) → (q x) .fst ≡ y
      h x y = (q x) .snd y
  in (( a , q a .fst)
     , ( λ x i → p (x .fst) i
       , h (p (x .fst) i) (transp (λ j → B (p (x .fst) (i ∨ ~ j))) i (x .snd)) i))

ΣProp≡
  : ((x : A) → isProp (B x)) → {u v : Σ[ a ∈ A ] B a}
  → (p : u .fst ≡ v .fst) → u ≡ v
ΣProp≡ pB {u} {v} p i = (p i) , isProp→PathP (λ i → pB (p i)) (u .snd) (v .snd) i

ΣProp≡-equiv
  : (pB : (x : A) → isProp (B x)) {u v : Σ[ a ∈ A ] B a}
  → isEquiv (ΣProp≡ pB {u} {v})
ΣProp≡-equiv {A = A} pB {u} {v} = isoToIsEquiv (iso (ΣProp≡ pB) (cong fst) sq (λ _ → refl))
  where sq : (p : u ≡ v) → ΣProp≡ pB (cong fst p) ≡ p
        sq p j i = (p i .fst) , isProp→PathP (λ i → isOfHLevelPath 1 (pB (fst (p i)))
                                                       (ΣProp≡ pB {u} {v} (cong fst p) i .snd)
                                                       (p i .snd) )
                                              refl refl i j

isPropΣ : isProp A → ((x : A) → isProp (B x)) → isProp (Σ[ x ∈ A ] B x)
isPropΣ pA pB t u = ΣProp≡ pB (pA (t .fst) (u .fst))

isOfHLevelΣ : ∀ n → isOfHLevel n A → ((x : A) → isOfHLevel n (B x))
  → isOfHLevel n (Σ A B)
isOfHLevelΣ 0 = isContrΣ
isOfHLevelΣ 1 = isPropΣ
isOfHLevelΣ {B = B} (suc (suc n)) h1 h2 x y =
  let h3 : isOfHLevel (suc n) (x Σ≡T y)
      h3 = isOfHLevelΣ (suc n) (h1 (fst x) (fst y)) λ p → h2 (p i1)
                       (subst B p (snd x)) (snd y)
  in transport (λ i → isOfHLevel (suc n) (pathSigma≡sigmaPath x y (~ i))) h3

-- h-level of Π-types

isOfHLevelPi
  : ∀ n
  → ((x : A) → isOfHLevel n (B x))
  → isOfHLevel n ((x : A) → B x)
isOfHLevelPi 0 h = (λ x → fst (h x)) , λ f i y → snd (h y) (f y) i
isOfHLevelPi 1 h f g i x = (h x) (f x) (g x) i
isOfHLevelPi (suc (suc n)) h f g =
  subst (isOfHLevel (suc n)) funExtPath (isOfHLevelPi (suc n) λ x → h x (f x) (g x))

isPropPi : (h : (x : A) → isProp (B x)) → isProp ((x : A) → B x)
isPropPi = isOfHLevelPi 1

isSetPi : ((x : A) → isSet (B x)) → isSet ((x : A) → B x)
isSetPi = isOfHLevelPi 2

isOfHLevelPi⁻ : ∀ {A : Type ℓ} {B : Type ℓ'} n
                → isOfHLevel n (A → B)
                → (A → isOfHLevel n B)
isOfHLevelPi⁻ 0 h x = fst h x , λ y → funExt⁻ (snd h (const y)) x
isOfHLevelPi⁻ 1 h x y z = funExt⁻ (h (const y) (const z)) x
isOfHLevelPi⁻ (suc (suc n)) h x y z =
  isOfHLevelPi⁻ (suc n) (subst (isOfHLevel (suc n)) (sym funExtPath) (h (const y) (const z))) x

-- h-level of A ≃ B and A ≡ B

isOfHLevel≃ : ∀ n → {A B : Type ℓ} (hA : isOfHLevel n A) (hB : isOfHLevel n B) → isOfHLevel n (A ≃ B)
isOfHLevel≃ zero {A = A} {B = B} hA hB = A≃B , contr
  where
  A≃B : A ≃ B
  A≃B = isoToEquiv (iso (λ _ → fst hB) (λ _ → fst hA) (snd hB ) (snd hA))

  contr : (y : A ≃ B) → A≃B ≡ y
  contr y = ΣProp≡ isPropIsEquiv (funExt (λ a → snd hB (fst y a)))

isOfHLevel≃ (suc n) hA hB =
  isOfHLevelΣ (suc n) (isOfHLevelPi (suc n) (λ _ → hB))
              (λ a → subst (λ n → isOfHLevel n (isEquiv a)) (+-comm n 1) (isOfHLevelPlus n (isPropIsEquiv a)))

isOfHLevel≡ : ∀ n → {A B : Type ℓ} (hA : isOfHLevel n A) (hB : isOfHLevel n B) →
  isOfHLevel n (A ≡ B)
isOfHLevel≡ n hA hB = isOfHLevelRespectEquiv n (invEquiv univalence) (isOfHLevel≃ n hA hB)

-- h-level of HLevel

isPropHContr : isProp (HLevel ℓ 0)
isPropHContr x y = ΣProp≡ (λ _ → isPropIsContr) ((isOfHLevel≡ 0 (x .snd) (y .snd) .fst))

isOfHLevelHLevel : ∀ n → isOfHLevel (suc n) (HLevel ℓ n)
isOfHLevelHLevel 0 = isPropHContr
isOfHLevelHLevel (suc n) x y = subst (isOfHLevel (suc n)) eq (isOfHLevel≡ (suc n) (snd x) (snd y))
  where eq : ∀ {A B : Type ℓ} {hA : isOfHLevel (suc n) A} {hB : isOfHLevel (suc n) B}
             → (A ≡ B) ≡ ((A , hA) ≡ (B , hB))
        eq = ua (_ , ΣProp≡-equiv (λ _ → isPropIsOfHLevel (suc n)))

isSetHProp : isSet (hProp ℓ)
isSetHProp = isOfHLevelHLevel 1

-- h-level of lifted type

isOfHLevelLift : ∀ {ℓ ℓ'} (n : ℕ) {A : Type ℓ} → isOfHLevel n A → isOfHLevel n (Lift {j = ℓ'} A)
isOfHLevelLift n = isOfHLevelRetract n lower lift λ _ → refl

----------------------------

-- More consequences of isProp and isContr

inhProp→isContr : A → isProp A → isContr A
inhProp→isContr x h = x , h x

isContrPartial→isContr : ∀ {ℓ} {A : Type ℓ}
                       → (extend : ∀ φ → Partial φ A → A)
                       → (∀ u → u ≡ (extend i1 λ { _ → u}))
                       → isContr A
isContrPartial→isContr {A = A} extend law
  = ex , λ y → law ex ∙ (λ i → Aux.v y i) ∙ sym (law y)
    where ex = extend i0 empty
          module Aux (y : A) (i : I) where
            φ = ~ i ∨ i
            u : Partial φ A
            u = λ { (i = i0) → ex ; (i = i1) → y }
            v = extend φ u

-- Dependent h-level over a type

isOfHLevelDep : ℕ → {A : Type ℓ} (B : A → Type ℓ') → Type (ℓ-max ℓ ℓ')
isOfHLevelDep 0 {A = A} B = {a : A} → Σ[ b ∈ B a ] ({a' : A} (b' : B a') (p : a ≡ a') → PathP (λ i → B (p i)) b b')
isOfHLevelDep 1 {A = A} B = {a0 a1 : A} (b0 : B a0) (b1 : B a1) (p : a0 ≡ a1)  → PathP (λ i → B (p i)) b0 b1
isOfHLevelDep (suc (suc  n)) {A = A} B = {a0 a1 : A} (b0 : B a0) (b1 : B a1) → isOfHLevelDep (suc n) {A = a0 ≡ a1} (λ p → PathP (λ i → B (p i)) b0 b1)

isOfHLevel→isOfHLevelDep : (n : ℕ)
  → {A : Type ℓ} {B : A → Type ℓ'} (h : (a : A) → isOfHLevel n (B a)) → isOfHLevelDep n {A = A} B
isOfHLevel→isOfHLevelDep 0 h {a} =
  (h a .fst , λ b' p → isProp→PathP (λ i → isContr→isProp (h (p i))) (h a .fst) b')
isOfHLevel→isOfHLevelDep 1 h = λ b0 b1 p → isProp→PathP (λ i → h (p i)) b0 b1
isOfHLevel→isOfHLevelDep (suc (suc n)) {A = A} {B} h {a0} {a1} b0 b1 =
  isOfHLevel→isOfHLevelDep (suc n) (λ p → helper a1 p b1)
  where
  helper : (a1 : A) (p : a0 ≡ a1) (b1 : B a1) →
    isOfHLevel (suc n) (PathP (λ i → B (p i)) b0 b1)
  helper a1 p b1 = J
                     (λ a1 p → ∀ b1 → isOfHLevel (suc n) (PathP (λ i → B (p i)) b0 b1))
                     (λ _ → h _ _ _) p b1
