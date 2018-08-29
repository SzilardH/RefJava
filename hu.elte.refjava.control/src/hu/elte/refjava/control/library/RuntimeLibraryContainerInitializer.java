package hu.elte.refjava.control.library;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.Path;
import org.eclipse.jdt.core.ClasspathContainerInitializer;
import org.eclipse.jdt.core.IClasspathContainer;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jdt.core.JavaCore;

public class RuntimeLibraryContainerInitializer extends ClasspathContainerInitializer {

	public static final Path LIBRARY_PATH = new Path("hu.elte.refjava.control.library");

	@Override
	public void initialize(IPath containerPath, IJavaProject project) throws CoreException {
		if (!LIBRARY_PATH.equals(containerPath)) {
			return;
		}

		IClasspathContainer container = new RuntimeLibraryContainer(containerPath);
		JavaCore.setClasspathContainer(containerPath, new IJavaProject[] { project },
				new IClasspathContainer[] { container }, null);
	}

}
