package hu.elte.refjava.control.library;

import org.eclipse.jdt.core.IClasspathEntry;
import org.eclipse.jdt.core.JavaCore;
import org.eclipse.jdt.ui.wizards.IClasspathContainerPage;
import org.eclipse.jdt.ui.wizards.NewElementWizardPage;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Label;

public class RuntimeLibraryContainerWizardPage extends NewElementWizardPage implements IClasspathContainerPage {

	private IClasspathEntry containerEntry;

	@SuppressWarnings("restriction")
	public RuntimeLibraryContainerWizardPage() {
		super("RuntimeLibraryContainer");
		setTitle("RefJava Runtime Library");
		setImageDescriptor(org.eclipse.jdt.internal.ui.JavaPluginImages.DESC_WIZBAN_ADD_LIBRARY);
		setDescription("RefJava Runtime Library");
		this.containerEntry = JavaCore.newContainerEntry(RuntimeLibraryContainerInitializer.LIBRARY_PATH);
	}

	@Override
	public void createControl(Composite parent) {
		Composite composite = new Composite(parent, SWT.NONE);
		composite.setLayout(new FillLayout());
		Label label = new Label(composite, SWT.NONE);
		String aboutText = "The RefJava Runtime Library contains:\n" + containedBundles();
		label.setText(aboutText);
		setControl(composite);
	}

	private String containedBundles() {
		StringBuilder builder = new StringBuilder();
		for (String bundleId : RuntimeLibraryContainer.BUNDLE_IDS_TO_INCLUDE) {
			builder.append("\t").append(bundleId).append("\n");
		}
		return builder.toString();
	}

	@Override
	public boolean finish() {
		return true;
	}

	@Override
	public IClasspathEntry getSelection() {
		return containerEntry;

	}

	@Override
	public void setSelection(IClasspathEntry containerEntry) {
		// intentionally left blank
	}

}
