{-# OPTIONS --cubical --safe #-}
module Cubical.Structures.Monoid where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.HLevels
open import Cubical.Data.Prod.Base hiding (_×_) renaming (_×Σ_ to _×_)

open import Cubical.Foundations.SIP renaming (SNS-PathP to SNS)

open import Cubical.Structures.Pointed
open import Cubical.Structures.InftyMagma

private
  variable
    ℓ : Level

-- Now we're getting serious: Monoids
raw-monoid-structure : Type ℓ → Type ℓ
raw-monoid-structure X = X × (X → X → X)

raw-monoid-iso : StrIso raw-monoid-structure ℓ
raw-monoid-iso (M , e , _·_) (N , d , _∗_) f =
    (equivFun f e ≡ d)
  × ((x y : M) → equivFun f (x · y) ≡ (equivFun f x) ∗ (equivFun f y))

-- If we ignore the axioms we get something like a "raw" monoid, which
-- essentially is the join of a pointed type and an ∞-magma
raw-monoid-is-SNS : SNS {ℓ} raw-monoid-structure raw-monoid-iso
raw-monoid-is-SNS = join-SNS pointed-structure pointed-iso pointed-is-SNS
                             ∞-magma-structure ∞-magma-iso ∞-magma-is-SNS

-- Now define monoids
monoid-axioms : (X : Type ℓ) → raw-monoid-structure X → Type ℓ
monoid-axioms X (e , _·_ ) = isSet X
                           × ((x y z : X) → (x · (y · z)) ≡ ((x · y) · z))
                           × ((x : X) → (x · e) ≡ x)
                           × ((x : X) → (e · x) ≡ x)

monoid-structure : Type ℓ → Type ℓ
monoid-structure = add-to-structure (raw-monoid-structure) monoid-axioms

Monoids : Type (ℓ-suc ℓ)
Monoids {ℓ} = TypeWithStr ℓ monoid-structure

monoid-iso : StrIso monoid-structure ℓ
monoid-iso = add-to-iso raw-monoid-structure raw-monoid-iso monoid-axioms

-- We have to show that the monoid axioms are indeed propositions
monoid-axioms-are-Props : (X : Type ℓ) (s : raw-monoid-structure X) → isProp (monoid-axioms X s)
monoid-axioms-are-Props X (e , _·_) s = β s
   where
   α = s .fst
   -- TODO: it would be nice to have versions of this lemmas for higher arities
   β =     isPropΣ isPropIsSet
     λ _ → isPropΣ (isPropPi (λ x → isPropPi (λ y → isPropPi (λ z → α (x · (y · z)) ((x · y) · z)))))
     λ _ → isPropΣ (isPropPi (λ x → α (x · e) x))
     λ _ →          isPropPi (λ x → α (e · x) x)

monoid-is-SNS : SNS {ℓ} monoid-structure monoid-iso
monoid-is-SNS = add-axioms-SNS raw-monoid-structure raw-monoid-iso
                               monoid-axioms monoid-axioms-are-Props raw-monoid-is-SNS

MonoidPath : (M N : Monoids {ℓ}) → (M ≃[ monoid-iso ] N) ≃ (M ≡ N)
MonoidPath M N = SIP monoid-structure monoid-iso monoid-is-SNS M N

-- Added for groups
-- If there exists a inverse of an element it is unique

inv-lemma : (X : Type ℓ) (e : X) (_·_ : X → X → X)
          → monoid-axioms X (e , _·_)
          → (x y z : X)
          → y · x ≡ e
          → x · z ≡ e
          → y ≡ z
inv-lemma X e _·_ (is-set-X , assoc , runit , lunit) x y z left-inverse right-inverse =
  y           ≡⟨ sym (runit y) ⟩
  y · e       ≡⟨ cong (y ·_) (sym right-inverse) ⟩
  y · (x · z) ≡⟨ assoc y x z ⟩
  (y · x) · z ≡⟨ cong (_· z) left-inverse ⟩
  e · z       ≡⟨ lunit z ⟩
  z ∎
