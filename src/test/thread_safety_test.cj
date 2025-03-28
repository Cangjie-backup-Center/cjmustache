package cjmustache.test

import cjmustache.*

import serialization.serialization.*
import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.collection.concurrent.*
import std.convert.*
import std.sync.*
import std.time.*

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
        let byteArrayStream = ByteArrayStream()
        byteArrayStream.write(templateA.toArray())
        let template = compiler.compile(BufferedInputStream(byteArrayStream))


        let threads = ArrayList<Future<Unit>>()
        for (_ in 0..nThreads) {
            let fut = spawn {
                try {
                    synchronized(mon) {
                        mon.wait()
                        let value = template.execute(HashMap<String, String>().serialize())
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
        let loader = AtomicTemplateLoader(loadCount)
        let template = Mustache.compiler().withLoader(loader)
        .compile("{{stuff}}\n\t{{> partial }}")
        let q = NonBlockingQueue<Exception>()

        let m = HashMap<String, String>()
        m.put("stuff", "Foo")
        let threads = ArrayList<Future<Unit>>()

        for (_ in 0..100) {
            let fut = spawn {
                try {
                    sleep(Duration.millisecond)
                    let skipStr = template.execute(m.serialize())
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
        if (!("templateB" == name)) {
            throw IllegalArgumentException()
        }
        let byteArrayStream = ByteArrayStream()
        byteArrayStream.write(ThreadSafetyTest.templateB.toArray())
        return BufferedInputStream(byteArrayStream)
    }

    public func count(): Int64 {
        return counter.load()
    }
}

public class AtomicTemplateLoader <: TemplateLoader {
    public AtomicTemplateLoader(let loadCount: AtomicInt64) {}

    public override func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        byteArrayStream.write("Hello".toArray())
        if ("partial" == name) {
            loadCount.fetchAdd(1)
            sleep(Duration.second)
            return BufferedInputStream(byteArrayStream)
        }
        throw IOException(name)
    }
}


