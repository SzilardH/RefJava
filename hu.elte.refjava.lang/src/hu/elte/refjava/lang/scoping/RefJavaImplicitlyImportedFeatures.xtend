package hu.elte.refjava.lang.scoping

import hu.elte.refjava.api.Check
import org.eclipse.xtext.xbase.scoping.batch.ImplicitlyImportedFeatures

class RefJavaImplicitlyImportedFeatures extends ImplicitlyImportedFeatures {

	override protected getStaticImportClasses() {
		(super.getStaticImportClasses() + #[Check]).toList
	}
}
