package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.collection.concurrent.*
import std.convert.*
import std.reflect.*
import std.sync.*

@Test
public class ThreadSafetyTest {
    public static let templateA = "Template A content\n{{> templateB}}"
    public static let templateB = "Template B content"

    @TestCase
    public func testTemplateLoading() {
        // 4096 works but is disabled as it makes the test take a long time
        for (ii in [ 1, 2, 4, 8, 16, 32, 256, 1024/* , 4096 */ ]) {
            templateLoadingIsThreadSafe(ii)
        }
    }

    public func templateLoadingIsThreadSafe(nThreads: Int64): Unit {
        let mon = Monitor()
        let loader = CountLoader()
        let compiler = Mustache.compiler().withLoader(loader)
        let template = compiler.compile(BufferedInputStream(ByteBuffer(templateA.toArray())))

        let threads = ArrayList<Future<Unit>>()
        for (_ in 0..nThreads) {
            let fut = spawn {
                try {
                    synchronized(mon) {
                        mon.wait()
                        let value = template.execute(ConcurrentHashMap<String, String>())
                        if (!value.contains("Template A content\nTemplate B content")) {
                            @Assert(false)
                        }
                    }
                } catch (e: Exception) {
                    throw MustacheException(e)
                }
            }

            threads.append(fut)
        }

        sleep(Duration.second)
        synchronized(mon) {
            mon.notifyAll()
        }

        for (f in threads) {
            f.get()
        }

        @Expect(1, loader.count())
    }

    @TestCase
    public func testPartialThreadSafe(): Unit {
        let loadCount = AtomicInt64(0)
        let loader = TemplateLoader5(loadCount)
        let template = Mustache.compiler().withLoader(loader)
        .compile("{{stuff}}\n\t{{> partial }}")
        let q = NonBlockingQueue<Exception>()

        let m = HashMap<String, Any>()
        m.put("stuff", "Foo")
        let threads = ArrayList<Future<Unit>>()

        for (_ in 0..100) {
            let fut = spawn {
                try {
                    sleep(Duration.millisecond)
                    let skipStr = template.execute(m)
                } catch (e: Exception) {
                    let skipBool = q.enqueue(e)
                }
            }
            threads.append(fut)
        }

        for (f in threads) {
            f.get()
        }

        @Expect(q.size, 0)
        @Expect(1, loadCount.load())
    }
}


public class CountLoader <: TemplateLoader {
    let counter = AtomicInt64(0)

    public func getTemplate(name: String): InputStream {
        counter.fetchAdd(1)
        if (!"templateB".equalsIgnoreAsciiCase(name)) {
            throw IllegalArgumentException()
        }
        return BufferedInputStream(ByteBuffer(ThreadSafetyTest.templateB.toArray()))
    }

    public func count(): Int64 {
        return counter.load()
    }
}

public class TemplateLoader5 <: TemplateLoader {
    public TemplateLoader5(let loadCount: AtomicInt64) {}

    public override func getTemplate(name: String): InputStream {
        if ("partial".equalsIgnoreAsciiCase(name)) {
            loadCount.fetchAdd(1)
            sleep(Duration.second)
            return BufferedInputStream(ByteBuffer("Hello".toArray()))
        }
        throw IOException(name)
    }
}


