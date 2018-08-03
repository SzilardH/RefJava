package hu.elte.refjava

class RefJavaStandaloneSetup extends RefJavaStandaloneSetupGenerated {

	def static void doSetup() {
		new RefJavaStandaloneSetup().createInjectorAndDoEMFRegistration()
	}

}
