using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.IO;
using System.Threading.Tasks;

class Runner {
  static async Task Main() {
    var token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OWViNjYxNzhmNjQyY2E5MzgyNDExODQiLCJyb2xlIjoiVEUiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzc4OTQ5OTQyLCJleHAiOjE3Nzg5NTcxNDJ9.KagYl8m_Za9n4qug-EIXV6Wp99CGx3kgopGitXmxPac";
    var body = File.ReadAllText("temp_test_result.json");
    using var client = new HttpClient();
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    using var content = new StringContent(body, Encoding.UTF8, "application/json");
    var response = await client.PostAsync("http://localhost:5000/api/structures/69f9b66a84c83140e9812150/test-results", content);
    Console.WriteLine("STATUS=" + (int)response.StatusCode);
    Console.WriteLine(await response.Content.ReadAsStringAsync());
  }
}
