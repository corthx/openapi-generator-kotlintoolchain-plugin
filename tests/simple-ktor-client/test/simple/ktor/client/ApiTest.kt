package simple.ktor.client

import org.openapitools.client.apis.DefaultApi
import org.openapitools.client.models.PostDto
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class ApiTest {
  @Test
  fun `PostDto can be instantiated with expected fields`() {
    val post = PostDto(id = 1, userId = 42, title = "Hello", body = "World")
    assertEquals(1, post.id)
    assertEquals(42, post.userId)
    assertEquals("Hello", post.title)
    assertEquals("World", post.body)
  }

  @Test
  fun `DefaultApi can be instantiated`() {
    val api = DefaultApi()
    assertNotNull(api)
  }
}