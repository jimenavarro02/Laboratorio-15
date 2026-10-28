package com.fieldtech;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class IncidenciaControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void listaIncidenciasSemilla() throws Exception {
        mockMvc.perform(get("/api/v1/incidencias"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()", greaterThanOrEqualTo(2)));
    }

    @Test
    void registraIncidenciaConFoto() throws Exception {
        MockMultipartFile foto = new MockMultipartFile(
                "foto", "poste.jpg", "image/jpeg", "contenido".getBytes());

        mockMvc.perform(multipart("/api/v1/incidencias")
                        .file(foto)
                        .param("titulo", "Poste caído")
                        .param("descripcion", "Poste caído sobre la vía")
                        .param("categoria", "INFRAESTRUCTURA")
                        .param("latitud", "9.9322")
                        .param("longitud", "-84.0795")
                        .param("tecnicoCodigo", "TEC-CR-001"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.estado").value("REGISTRADA"))
                .andExpect(jsonPath("$.fotoUrl").isNotEmpty());
    }
}
