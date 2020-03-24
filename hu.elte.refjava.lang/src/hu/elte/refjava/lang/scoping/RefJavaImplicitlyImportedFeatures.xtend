package hu.elte.refjava.lang.scoping

import org.eclipse.xtext.xbase.scoping.batch.ImplicitlyImportedFeatures
import hu.elte.refjava.api.Check

class RefJavaImplicitlyImportedFeatures extends ImplicitlyImportedFeatures {

	override protected getStaticImportClasses() {
		(super.getStaticImportClasses() + #[Check]).toList
	}
}
